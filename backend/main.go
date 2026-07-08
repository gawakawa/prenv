package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	run "cloud.google.com/go/run/apiv2"
	"cloud.google.com/go/storage"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func upsertRunningPrenvs(ctx context.Context, db *sql.DB, prenvs []Prenv) error {
	for _, p := range prenvs {
		_, err := db.ExecContext(ctx, `
			INSERT INTO prenvs (pr_number, name, url, status, commit_sha, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6::timestamptz)
			ON CONFLICT (pr_number) DO UPDATE SET
				name = EXCLUDED.name,
				url = EXCLUDED.url,
				status = EXCLUDED.status,
				commit_sha = EXCLUDED.commit_sha,
				updated_at = EXCLUDED.updated_at`,
			p.PRNumber, p.Name, p.URL, p.Status, p.CommitSHA, p.UpdatedAt)
		if err != nil {
			return err
		}
	}
	return nil
}

// markTornDown flips status to "torn_down" for PR numbers no longer running,
// preserving whatever name/url/commit_sha/updated_at was last observed live.
func markTornDown(ctx context.Context, db *sql.DB, prNumbers []int) error {
	for _, n := range prNumbers {
		_, err := db.ExecContext(ctx, `
			INSERT INTO prenvs (pr_number, name, url, status, commit_sha, updated_at)
			VALUES ($1, '', '', 'torn_down', '', now())
			ON CONFLICT (pr_number) DO UPDATE SET status = 'torn_down'`,
			n)
		if err != nil {
			return err
		}
	}
	return nil
}

func selectPrenvs(ctx context.Context, db *sql.DB) ([]Prenv, error) {
	rows, err := db.QueryContext(ctx, "SELECT pr_number, name, url, status, commit_sha, updated_at FROM prenvs ORDER BY pr_number")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	prenvs := []Prenv{}
	for rows.Next() {
		var p Prenv
		var updatedAt time.Time
		if err := rows.Scan(&p.PRNumber, &p.Name, &p.URL, &p.Status, &p.CommitSHA, &updatedAt); err != nil {
			return nil, err
		}
		p.UpdatedAt = updatedAt.Format(time.RFC3339)
		prenvs = append(prenvs, p)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return prenvs, nil
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

	http.HandleFunc("GET /api/prenvs", func(w http.ResponseWriter, r *http.Request) {
		if runClient == nil || gcsClient == nil {
			http.Error(w, "monitoring unavailable", http.StatusServiceUnavailable)
			return
		}

		ctx := r.Context()

		running, err := listRunningPrenvs(ctx, runClient)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		tornDown, err := listTornDownPRNumbers(ctx, gcsClient, gcsBucket, repo, running)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if err := upsertRunningPrenvs(ctx, db, running); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if err := markTornDown(ctx, db, tornDown); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		prenvs, err := selectPrenvs(ctx, db)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(prenvs)
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
