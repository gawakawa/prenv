package main

import (
	"context"
	"path"
	"regexp"
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

// repoSlug mirrors terraform/modules/preview's repo_slug: OWNER and REPO are
// sanitized independently and joined with "--" (rather than sanitizing
// "owner/repo" as one string), so that e.g. "a/b-c" and "a-b/c" can't
// collapse to the same slug and be mistaken for one another's Cloud Run
// services.
func repoSlug(repo string) string {
	owner, name, _ := strings.Cut(repo, "/")
	return sanitizeSlugPart(owner) + "--" + sanitizeSlugPart(name)
}

func sanitizeSlugPart(s string) string {
	return strings.ToLower(nonAlnumRun.ReplaceAllString(s, "-"))
}

// withinGracePeriod reports whether updated is recent enough that the
// tfstate object it belongs to was touched very recently — either because a
// deploy just started or a teardown just finished, per the tornDownGracePeriod
// comment on listPrenvsFromTfstate.
func withinGracePeriod(updated, now time.Time) bool {
	return updated.After(now.Add(-tornDownGracePeriod))
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

	return prenvs, nil
}

// listPrenvsFromTfstate returns a Prenv per gs://<bucket>/<repo>/pr/<N>/default.tfstate
// object that isn't in live, mirroring the object-discovery approach
// reusable-gc-prenv.yml uses. Its Name mirrors the Cloud Run service name
// format (runningPrefix + PR number) so the same PR looks the same whether
// it's currently live or not. Its UpdatedAt is the tfstate object's own
// Updated time (the closest available signal, since there's no persisted
// history to draw a real teardown time from).
//
// A tfstate write lands both when a PR starts deploying (before the Cloud
// Run service is visible via ListServices) and when a PR finishes tearing
// down — the two can't be told apart from the object's Updated time alone.
// Objects touched within tornDownGracePeriod are therefore reported as
// "pending" rather than "torn_down", so a PR never silently vanishes from
// the list; the next poll resolves it once the grace period elapses or the
// service reappears in live. Listing individual objects (rather than
// grouping by common prefix) is required to read each object's Updated time
// for this check.
func listPrenvsFromTfstate(ctx context.Context, client *storage.Client, bucket, repo, runningPrefix string, live []Prenv) ([]Prenv, error) {
	liveSet := make(map[int]bool, len(live))
	for _, p := range live {
		liveSet[p.PRNumber] = true
	}

	prefix := repo + "/pr/"
	it := client.Bucket(bucket).Objects(ctx, &storage.Query{Prefix: prefix})

	now := time.Now()
	prenvs := []Prenv{}
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
		rest := strings.TrimPrefix(attrs.Name, prefix)
		seg, _, ok := strings.Cut(rest, "/")
		if !ok {
			continue
		}
		n, err := strconv.Atoi(seg)
		if err != nil {
			continue
		}
		if liveSet[n] {
			continue
		}
		status := "torn_down"
		if withinGracePeriod(attrs.Updated, now) {
			status = "pending"
		}
		prenvs = append(prenvs, Prenv{
			PRNumber:  n,
			Name:      runningPrefix + strconv.Itoa(n),
			Status:    status,
			UpdatedAt: attrs.Updated.Format(time.RFC3339),
		})
	}

	return prenvs, nil
}
