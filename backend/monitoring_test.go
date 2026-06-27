package main

import (
	"testing"

	"cloud.google.com/go/run/apiv2/runpb"
)

func TestParsePRNumber(t *testing.T) {
	tests := []struct {
		name   string
		input  string
		wantN  int
		wantOK bool
	}{
		{"match", "prenv-pr-42", 42, true},
		{"non-numeric suffix", "prenv-pr-main", 0, false},
		{"no prefix", "some-service", 0, false},
		{"empty", "", 0, false},
		{"only prefix", "prenv-pr-", 0, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			n, ok := parsePRNumber(tt.input)
			if ok != tt.wantOK || n != tt.wantN {
				t.Errorf("parsePRNumber(%q) = (%d, %v), want (%d, %v)", tt.input, n, ok, tt.wantN, tt.wantOK)
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
