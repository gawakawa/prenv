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

	var runClient *run.ServicesClient
	if client, err := run.NewServicesClient(context.Background()); err != nil {
		log.Printf("monitoring disabled: %v", err)
	} else {
		runClient = client
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

		if runClient != nil {
			_, _ = fmt.Fprintln(w)
			envs, err := listEnvironments(r.Context(), runClient)
			if err != nil {
				log.Printf("list environments: %v", err)
				_, _ = fmt.Fprintf(w, "monitoring unavailable: %v\n", err)
			} else {
				for _, env := range envs {
					_, _ = fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n",
						env.Name, env.Status, env.CommitSHA, env.URL, env.UpdatedAt)
				}
			}
		}
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
