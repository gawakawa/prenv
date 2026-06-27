package main

import (
	"encoding/json"
	"net/http"
	"path"
	"sort"
	"strconv"
	"strings"
	"time"

	run "cloud.google.com/go/run/apiv2"
	"cloud.google.com/go/run/apiv2/runpb"
	"google.golang.org/api/iterator"
)

type Environment struct {
	PRNumber  int    `json:"pr_number"`
	Name      string `json:"name"`
	URL       string `json:"url"`
	Status    string `json:"status"`
	CommitSHA string `json:"commit_sha"`
	UpdatedAt string `json:"updated_at"`
}

func parsePRNumber(name string) (int, bool) {
	const prefix = "prenv-pr-"
	if !strings.HasPrefix(name, prefix) {
		return 0, false
	}
	n, err := strconv.Atoi(name[len(prefix):])
	if err != nil {
		return 0, false
	}
	return n, true
}

func parseCommitSHA(image string) string {
	if strings.Contains(image, "@") {
		return ""
	}
	lastSlash := strings.LastIndex(image, "/")
	lastColon := strings.LastIndex(image, ":")
	if lastColon <= lastSlash {
		return ""
	}
	return image[lastColon+1:]
}

func mapStatus(state runpb.Condition_State) string {
	switch state {
	case runpb.Condition_CONDITION_SUCCEEDED:
		return "succeeded"
	case runpb.Condition_CONDITION_FAILED:
		return "failed"
	case runpb.Condition_CONDITION_RECONCILING:
		return "reconciling"
	case runpb.Condition_CONDITION_PENDING:
		return "pending"
	default:
		return "unknown"
	}
}

func toEnvironment(svc *runpb.Service) (Environment, bool) {
	base := path.Base(svc.GetName())
	n, ok := parsePRNumber(base)
	if !ok {
		return Environment{}, false
	}

	var image string
	for _, c := range svc.GetTemplate().GetContainers() {
		if c.GetName() == "app" {
			image = c.GetImage()
			break
		}
	}
	if image == "" && len(svc.GetTemplate().GetContainers()) > 0 {
		image = svc.GetTemplate().GetContainers()[0].GetImage()
	}

	return Environment{
		PRNumber:  n,
		Name:      base,
		URL:       svc.GetUri(),
		Status:    mapStatus(svc.GetTerminalCondition().GetState()),
		CommitSHA: parseCommitSHA(image),
		UpdatedAt: svc.GetUpdateTime().AsTime().Format(time.RFC3339),
	}, true
}

func environmentsHandler(client *run.ServicesClient, project, region string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		parent := "projects/" + project + "/locations/" + region
		it := client.ListServices(r.Context(), &runpb.ListServicesRequest{Parent: parent})

		var envs []Environment
		for {
			svc, err := it.Next()
			if err == iterator.Done {
				break
			}
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			if env, ok := toEnvironment(svc); ok {
				envs = append(envs, env)
			}
		}

		sort.Slice(envs, func(i, j int) bool {
			return envs[i].PRNumber < envs[j].PRNumber
		})

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(envs)
	}
}
