# Contributing

## Development environment

direnv loads the Nix devShell automatically on `cd` and installs pre-commit hooks.

```bash
nix fmt          # format
nix flake check  # format + lint
```

## terraform/base

Applied locally by the project owner, not by CI:

```bash
cd terraform/base
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
tofu init
tofu apply
```
