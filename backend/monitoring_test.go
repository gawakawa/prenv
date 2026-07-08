package main

import (
	"testing"
	"time"

	"cloud.google.com/go/run/apiv2/runpb"
)

func TestParsePRNumber(t *testing.T) {
	tests := []struct {
		name   string
		input  string
		prefix string
		wantN  int
		wantOK bool
	}{
		{"match", "prenv-pr-42", "prenv-pr-", 42, true},
		{"non-numeric suffix", "prenv-pr-main", "prenv-pr-", 0, false},
		{"no prefix", "some-service", "prenv-pr-", 0, false},
		{"empty", "", "prenv-pr-", 0, false},
		{"only prefix", "prenv-pr-", "prenv-pr-", 0, false},
		{"repo-scoped prefix", "gawakawa-prenv-pr-42", "gawakawa-prenv-pr-", 42, true},
		{"different repo's service name is not matched", "otherrepo-pr-42", "gawakawa-prenv-pr-", 0, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			n, ok := parsePRNumber(tt.input, tt.prefix)
			if ok != tt.wantOK || n != tt.wantN {
				t.Errorf("parsePRNumber(%q, %q) = (%d, %v), want (%d, %v)", tt.input, tt.prefix, n, ok, tt.wantN, tt.wantOK)
			}
		})
	}
}

func TestRepoSlug(t *testing.T) {
	tests := []struct {
		name string
		repo string
		want string
	}{
		{"owner slash repo", "gawakawa/prenv", "gawakawa--prenv"},
		{"already hyphenated", "my-org/my-repo", "my-org--my-repo"},
		{"mixed case", "Gawakawa/Prenv", "gawakawa--prenv"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := repoSlug(tt.repo); got != tt.want {
				t.Errorf("repoSlug(%q) = %q, want %q", tt.repo, got, tt.want)
			}
		})
	}
}

func TestRepoSlugDoesNotCollideAcrossSlashPosition(t *testing.T) {
	a := repoSlug("gawakawa/prenv-x")
	b := repoSlug("gawakawa-prenv/x")
	if a == b {
		t.Errorf("repoSlug(%q) and repoSlug(%q) both produced %q, want distinct slugs", "gawakawa/prenv-x", "gawakawa-prenv/x", a)
	}
}

func TestWithinGracePeriod(t *testing.T) {
	now := time.Date(2026, 7, 9, 12, 0, 0, 0, time.UTC)
	tests := []struct {
		name    string
		updated time.Time
		want    bool
	}{
		{"just updated", now, true},
		{"1 minute ago", now.Add(-1 * time.Minute), true},
		{"9m59s ago, just inside the window", now.Add(-9*time.Minute - 59*time.Second), true},
		{"exactly at the boundary", now.Add(-tornDownGracePeriod), false},
		{"11 minutes ago, outside the window", now.Add(-11 * time.Minute), false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := withinGracePeriod(tt.updated, now); got != tt.want {
				t.Errorf("withinGracePeriod(%v, %v) = %v, want %v", tt.updated, now, got, tt.want)
			}
		})
	}
}

func TestParseCommitSHA(t *testing.T) {
	tests := []struct {
		name  string
		image string
		want  string
	}{
		{"tag", "asia-northeast1-docker.pkg.dev/proj/repo/app:abc1234", "abc1234"},
		{"digest", "asia-northeast1-docker.pkg.dev/proj/repo/app@sha256:deadbeef", ""},
		{"no tag", "asia-northeast1-docker.pkg.dev/proj/repo/app", ""},
		{"host port no tag", "localhost:5000/app", ""},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := parseCommitSHA(tt.image); got != tt.want {
				t.Errorf("parseCommitSHA(%q) = %q, want %q", tt.image, got, tt.want)
			}
		})
	}
}

func TestMapStatus(t *testing.T) {
	tests := []struct {
		name  string
		state runpb.Condition_State
		want  string
	}{
		{"succeeded", runpb.Condition_CONDITION_SUCCEEDED, "succeeded"},
		{"failed", runpb.Condition_CONDITION_FAILED, "failed"},
		{"reconciling", runpb.Condition_CONDITION_RECONCILING, "reconciling"},
		{"pending", runpb.Condition_CONDITION_PENDING, "pending"},
		{"unspecified", runpb.Condition_STATE_UNSPECIFIED, "unknown"},
		{"unknown_value", runpb.Condition_State(99), "unknown"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := mapStatus(tt.state); got != tt.want {
				t.Errorf("mapStatus(%v) = %q, want %q", tt.state, got, tt.want)
			}
		})
	}
}
