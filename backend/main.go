package main

import (
	"cmp"
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"slices"
	"strings"

	run "cloud.google.com/go/run/apiv2"
	"cloud.google.com/go/storage"
	_ "github.com/jackc/pgx/v5/stdlib"
)

// failRequest writes a 500 response and reports whether err was non-nil, so
// callers can write `if failRequest(w, err) { return }`.
func failRequest(w http.ResponseWriter, err error) bool {
	if err == nil {
		return false
	}
	http.Error(w, err.Error(), http.StatusInternalServerError)
	return true
}

type Message struct {
	ID   int    `json:"id"`
	Body string `json:"body"`
}

func selectMessages(ctx context.Context, db *sql.DB) ([]Message, error) {
	rows, err := db.QueryContext(ctx, "SELECT id, body FROM messages ORDER BY id")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	messages := []Message{}
	for rows.Next() {
		var m Message
		if err := rows.Scan(&m.ID, &m.Body); err != nil {
			return nil, err
		}
		messages = append(messages, m)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return messages, nil
}

func main() {
	db, err := sql.Open("pgx", os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal(err)
	}

	runClient, err := run.NewServicesClient(context.Background())
	if err != nil {
		log.Printf("monitoring disabled: %v", err)
		runClient = nil
	}

	gcsClient, err := storage.NewClient(context.Background())
	if err != nil {
		log.Printf("gcs disabled: %v", err)
		gcsClient = nil
	}
	gcsBucket := os.Getenv("GCS_BUCKET")
	repo := os.Getenv("REPO")
	if !strings.Contains(repo, "/") {
		// Reuses the monitoring-disabled fallback below (runClient == nil)
		// instead of log.Fatal, so a bad REPO only takes down /api/prenvs
		// and not the unrelated /api/messages handler.
		log.Printf("monitoring disabled: REPO must be in OWNER/REPO form, got %q", repo)
		runClient = nil
	}
	runningPrefix := repoSlug(repo) + "-pr-"

	http.HandleFunc("GET /api/messages", func(w http.ResponseWriter, r *http.Request) {
		messages, err := selectMessages(r.Context(), db)
		if failRequest(w, err) {
			return
		}

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(messages)
	})

	http.HandleFunc("GET /api/prenvs", func(w http.ResponseWriter, r *http.Request) {
		if runClient == nil || gcsClient == nil {
			http.Error(w, "monitoring unavailable", http.StatusServiceUnavailable)
			return
		}

		ctx := r.Context()

		running, err := listRunningPrenvs(ctx, runClient, runningPrefix)
		if failRequest(w, err) {
			return
		}
		tornDown, err := listPrenvsFromTfstate(ctx, gcsClient, gcsBucket, repo, runningPrefix, running)
		if failRequest(w, err) {
			return
		}

		prenvs := append(running, tornDown...)
		slices.SortFunc(prenvs, func(a, b Prenv) int { return cmp.Compare(a.PRNumber, b.PRNumber) })

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(prenvs)
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
