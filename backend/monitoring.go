package main

import (
	"cmp"
	"context"
	"path"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"time"

	run "cloud.google.com/go/run/apiv2"
	"cloud.google.com/go/run/apiv2/runpb"
	"cloud.google.com/go/storage"
	"google.golang.org/api/iterator"
)

const (
	project = "gawakawa-prenv"
	region  = "asia-northeast1"
	parent  = "projects/" + project + "/locations/" + region

	// tornDownGracePeriod mirrors reusable-gc-prenv.yml's own grace window
	// (there 3 days, here much shorter): a tfstate object can appear before
	// the matching Cloud Run service is visible via ListServices, so recently
	// touched objects are not yet treated as torn down.
	tornDownGracePeriod = 10 * time.Minute

	tfstateObjectName = "default.tfstate"
)

type Prenv struct {
	PRNumber  int    `json:"pr_number"`
	Name      string `json:"name"`
	URL       string `json:"url"`
	Status    string `json:"status"`
	CommitSHA string `json:"commit_sha"`
	UpdatedAt string `json:"updated_at"`
}

var nonAlnumRun = regexp.MustCompile(`[^a-zA-Z0-9]+`)

// repoSlug mirrors terraform/modules/preview's
// lower(replace(var.repo, "/[^a-zA-Z0-9]+/", "-")), which is how Cloud Run
// service names are derived from the "owner/repo" string.
func repoSlug(repo string) string {
	return strings.ToLower(nonAlnumRun.ReplaceAllString(repo, "-"))
}

func parsePRNumber(name, prefix string) (int, bool) {
	rest, ok := strings.CutPrefix(name, prefix)
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

func toPrenv(svc *runpb.Service, prefix string) (Prenv, bool) {
	base := path.Base(svc.GetName())
	n, ok := parsePRNumber(base, prefix)
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

func listRunningPrenvs(ctx context.Context, client *run.ServicesClient, prefix string) ([]Prenv, error) {
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
		if p, ok := toPrenv(svc, prefix); ok {
			prenvs = append(prenvs, p)
		}
	}

	slices.SortFunc(prenvs, func(a, b Prenv) int {
		return cmp.Compare(a.PRNumber, b.PRNumber)
	})

	return prenvs, nil
}

// listTornDownPRNumbers returns PR numbers that have a gs://<bucket>/<repo>/pr/<N>/default.tfstate
// object but are not in live, mirroring the object-discovery approach
// reusable-gc-prenv.yml uses. Objects touched within tornDownGracePeriod are
// skipped: a tfstate write can land before the matching Cloud Run service is
// visible via ListServices, so a PR mid-deploy must not be misread as torn
// down. Listing individual objects (rather than grouping by common prefix)
// is required to read each object's Updated time for this check.
func listTornDownPRNumbers(ctx context.Context, client *storage.Client, bucket, repo string, live []Prenv) ([]int, error) {
	liveSet := make(map[int]bool, len(live))
	for _, p := range live {
		liveSet[p.PRNumber] = true
	}

	prefix := repo + "/pr/"
	it := client.Bucket(bucket).Objects(ctx, &storage.Query{Prefix: prefix})

	cutoff := time.Now().Add(-tornDownGracePeriod)
	nums := []int{}
	for {
		attrs, err := it.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return nil, err
		}
		if !strings.HasSuffix(attrs.Name, "/"+tfstateObjectName) {
			continue
		}
		if attrs.Updated.After(cutoff) {
			continue
		}
		rest := strings.TrimPrefix(attrs.Name, prefix)
		seg, _, ok := strings.Cut(rest, "/")
		if !ok {
			continue
		}
		n, err := strconv.Atoi(seg)
		if err != nil {
			continue
		}
		if !liveSet[n] {
			nums = append(nums, n)
		}
	}

	slices.Sort(nums)
	return nums, nil
}
