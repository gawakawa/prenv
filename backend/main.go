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

// failRequest writes a 500 response and reports whether err was non-nil, so
// callers can write `if failRequest(w, err) { return }`.
func failRequest(w http.ResponseWriter, err error) bool {
	if err == nil {
		return false
	}
	http.Error(w, err.Error(), http.StatusInternalServerError)
	return true
}

// execer is satisfied by both *sql.DB and *sql.Tx, so upsertRunningPrenvs and
// markTornDown can run standalone or inside a shared transaction.
type execer interface {
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
}

func upsertRunningPrenvs(ctx context.Context, db execer, prenvs []Prenv) error {
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

// markTornDown flips status to "torn_down" and clears the now-dead url for PR
// numbers no longer running, while preserving name/commit_sha as historical
// reference. It only updates rows this backend has actually observed live
// before (via upsertRunningPrenvs) — a PR number found only in tfstate is not
// inserted as a blank placeholder.
func markTornDown(ctx context.Context, db execer, prNumbers []int) error {
	for _, n := range prNumbers {
		_, err := db.ExecContext(ctx, `
			UPDATE prenvs SET status = 'torn_down', url = '', updated_at = now()
			WHERE pr_number = $1`,
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
	runningPrefix := repoSlug(repo) + "-pr-"

	http.HandleFunc("GET /api/prenvs", func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()

		// Refresh the DB from Cloud Run/GCS when monitoring is available, but
		// always fall back to serving whatever prenvs are already in the DB —
		// a monitoring outage shouldn't take down the whole dashboard.
		if runClient != nil && gcsClient != nil {
			running, err := listRunningPrenvs(ctx, runClient, runningPrefix)
			if failRequest(w, err) {
				return
			}
			tornDown, err := listTornDownPRNumbers(ctx, gcsClient, gcsBucket, repo, running)
			if failRequest(w, err) {
				return
			}

			tx, err := db.BeginTx(ctx, nil)
			if failRequest(w, err) {
				return
			}
			defer tx.Rollback() //nolint:errcheck // no-op once Commit succeeds

			if failRequest(w, upsertRunningPrenvs(ctx, tx, running)) {
				return
			}
			if failRequest(w, markTornDown(ctx, tx, tornDown)) {
				return
			}
			if failRequest(w, tx.Commit()) {
				return
			}
		}

		prenvs, err := selectPrenvs(ctx, db)
		if failRequest(w, err) {
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
