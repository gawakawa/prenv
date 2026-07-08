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

type Prenv struct {
	PRNumber  int    `json:"pr_number"`
	Name      string `json:"name"`
	URL       string `json:"url"`
	Status    string `json:"status"`
	CommitSHA string `json:"commit_sha"`
	UpdatedAt string `json:"updated_at"`
}

func parsePRNumber(name string) (int, bool) {
	rest, ok := strings.CutPrefix(name, "prenv-pr-")
	if !ok {
		return 0, false
	}
	n, err := strconv.Atoi(rest)
	if err != nil {
		return 0, false
	}
	return n, true
}

func parseCommitSHA(image string) string {
	if strings.Contains(image, "@") {
		return ""
	}
	if i := strings.LastIndex(image, ":"); i > strings.LastIndex(image, "/") {
		return image[i+1:]
	}
	return ""
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

func toPrenv(svc *runpb.Service) (Prenv, bool) {
	base := path.Base(svc.GetName())
	n, ok := parsePRNumber(base)
	if !ok {
		return Prenv{}, false
	}

	var image string
	for _, c := range svc.GetTemplate().GetContainers() {
		if c.GetName() == "backend" {
			image = c.GetImage()
			break
		}
	}

	return Prenv{
		PRNumber:  n,
		Name:      base,
		URL:       svc.GetUri(),
		Status:    mapStatus(svc.GetTerminalCondition().GetState()),
		CommitSHA: parseCommitSHA(image),
		UpdatedAt: svc.GetUpdateTime().AsTime().Format(time.RFC3339),
	}, true
}

func listRunningPrenvs(ctx context.Context, client *run.ServicesClient) ([]Prenv, error) {
	it := client.ListServices(ctx, &runpb.ListServicesRequest{Parent: parent})

	prenvs := []Prenv{}
	for {
		svc, err := it.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return nil, err
		}
		if p, ok := toPrenv(svc); ok {
			prenvs = append(prenvs, p)
		}
	}

	slices.SortFunc(prenvs, func(a, b Prenv) int {
		return cmp.Compare(a.PRNumber, b.PRNumber)
	})

	return prenvs, nil
}
