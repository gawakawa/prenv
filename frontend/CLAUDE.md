# CLAUDE.md

## Commands

- `nix fmt` - Format code
- `nix flake check` - Run checks (format, lint)
- `nix build` - Build the project
- `pnpm test` - Run tests

## Updating dependencies

After changing dependencies, run `nix flake check` and copy the correct hash from the `got:` line in the error output into `flakes/checks.nix`.
