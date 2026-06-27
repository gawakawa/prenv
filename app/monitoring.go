package main

import (
	"cmp"
	"context"
	"encoding/json"
	"os"
	"path"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"time"

	"cloud.google.com/go/compute/metadata"
	run "cloud.google.com/go/run/apiv2"
	"cloud.google.com/go/run/apiv2/runpb"
	"google.golang.org/api/iterator"
)

const region = "asia-northeast1"

type Environment struct {
	PRNumber  int
	Name      string
	URL       string
	Status    string
	CommitSHA string
	UpdatedAt string
}

func detectProject(ctx context.Context) string {
	if metadata.OnGCE() {
		if id, err := metadata.ProjectIDWithContext(ctx); err == nil && id != "" {
			return id
		}
	}
	return projectFromADC()
}

func projectFromADC() string {
	p := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
	if p == "" {
		dir := os.Getenv("CLOUDSDK_CONFIG")
		if dir == "" {
			home, err := os.UserHomeDir()
			if err != nil {
				return ""
			}
			dir = filepath.Join(home, ".config", "gcloud")
		}
		p = filepath.Join(dir, "application_default_credentials.json")
	}
	data, err := os.ReadFile(p)
	if err != nil {
		return ""
	}
	var f struct {
		ProjectID      string `json:"project_id"`
		QuotaProjectID string `json:"quota_project_id"`
	}
	if err := json.Unmarshal(data, &f); err != nil {
		return ""
	}
	if f.ProjectID != "" {
		return f.ProjectID
	}
	return f.QuotaProjectID
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

	return Environment{
		PRNumber:  n,
		Name:      base,
		URL:       svc.GetUri(),
		Status:    mapStatus(svc.GetTerminalCondition().GetState()),
		CommitSHA: parseCommitSHA(image),
		UpdatedAt: svc.GetUpdateTime().AsTime().Format(time.RFC3339),
	}, true
}

func listEnvironments(ctx context.Context, client *run.ServicesClient, project string) ([]Environment, error) {
	parent := "projects/" + project + "/locations/" + region
	it := client.ListServices(ctx, &runpb.ListServicesRequest{Parent: parent})

	var envs []Environment
	for {
		svc, err := it.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return nil, err
		}
		if env, ok := toEnvironment(svc); ok {
			envs = append(envs, env)
		}
	}

	slices.SortFunc(envs, func(a, b Environment) int {
		return cmp.Compare(a.PRNumber, b.PRNumber)
	})

	return envs, nil
}
