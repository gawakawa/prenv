# CLAUDE.md

A Google Cloud version of the per-PR preview environment setup in this blog post:
https://www.m3tech.blog/entry/2026/06/16/153849
For each PR, provision an isolated, ephemeral preview environment on Google Cloud with Terraform + GitHub Actions, then tear it down when the PR is closed.

## Docs

- `README.md` — User-facing: setup and usage.
- `CONTRIBUTING.md` — Contributor-facing: dev environment setup and how to submit changes.
- `docs/DESIGN.md` — Developer-facing: design decisions and rationale.

## Commands

- `nix fmt` - Format code
- `nix flake check` - Run checks (format, lint)
- `nix build` - Build the project
