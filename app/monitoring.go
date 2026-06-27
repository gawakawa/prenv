package main

import (
	"cmp"
	"context"
	"path"
	"slices"
	"strconv"
	"strings"
	"time"

	run "cloud.google.com/go/run/apiv2"
	"cloud.google.com/go/run/apiv2/runpb"
	"google.golang.org/api/iterator"
)

const (
	project = "gawakawa-prenv"
	region  = "asia-northeast1"
	parent  = "projects/" + project + "/locations/" + region
)

type Environment struct {
	PRNumber  int
	Name      string
	URL       string
	Status    string
	CommitSHA string
	UpdatedAt string
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

func listEnvironments(ctx context.Context, client *run.ServicesClient) ([]Environment, error) {
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
