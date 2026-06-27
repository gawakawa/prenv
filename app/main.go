package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"

	run "cloud.google.com/go/run/apiv2"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func main() {
	db, err := sql.Open("pgx", os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal(err)
	}

	type monitoringConfig struct {
		client  *run.ServicesClient
		project string
		region  string
	}
	var monitoring *monitoringConfig
	if project := os.Getenv("GCP_PROJECT_ID"); project != "" {
		region := os.Getenv("REGION")
		if region == "" {
			region = "asia-northeast1"
		}
		client, err := run.NewServicesClient(context.Background())
		if err != nil {
			log.Fatal(err)
		}
		monitoring = &monitoringConfig{client, project, region}
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		rows, err := db.Query("SELECT body FROM messages ORDER BY id")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer func() { _ = rows.Close() }()

		var bodies []string
		for rows.Next() {
			var body string
			if err := rows.Scan(&body); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			bodies = append(bodies, body)
		}
		if err := rows.Err(); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		for _, body := range bodies {
			_, _ = fmt.Fprintln(w, body)
		}

		if monitoring != nil {
			envs, err := listEnvironments(r.Context(), monitoring.client, monitoring.project, monitoring.region)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			_, _ = fmt.Fprintln(w)
			for _, env := range envs {
				_, _ = fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n",
					env.Name, env.Status, env.CommitSHA, env.URL, env.UpdatedAt)
			}
		}
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
