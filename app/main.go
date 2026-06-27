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
	})

	if project := os.Getenv("GCP_PROJECT_ID"); project != "" {
		region := os.Getenv("REGION")
		if region == "" {
			region = "asia-northeast1"
		}
		client, err := run.NewServicesClient(context.Background())
		if err != nil {
			log.Fatal(err)
		}
		http.Handle("GET /environments", environmentsHandler(client, project, region))
	}

	log.Fatal(http.ListenAndServe(":8080", nil))
}
