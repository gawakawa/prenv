_: {
  perSystem =
    { pkgs, ... }:
    {
      pre-commit.settings.hooks = {
        treefmt.enable = true;
        statix.enable = true;
        deadnix.enable = true;
        actionlint.enable = true;
        zizmor = {
          enable = true;
          # pass_filenames=false: always audit the full directory so that files
          # using new step syntax (background:/wait:) don't leave zizmor with
          # no valid inputs (zizmor 1.25.2 schema predates the 2026-06-25 GA).
          pass_filenames = false;
          entry = "${pkgs.zizmor}/bin/zizmor --offline .github/workflows/";
        };
        hadolint.enable = true;
        tflint.enable = true;
        terraform-docs-base = {
          enable = true;
          entry = "${pkgs.terraform-docs}/bin/terraform-docs terraform/base";
          files = "^terraform/base/[^/]+\\.tf$";
          pass_filenames = false;
        };
        terraform-docs-env-pr = {
          enable = true;
          entry = "${pkgs.terraform-docs}/bin/terraform-docs terraform/env/pr";
          files = "^terraform/env/pr/[^/]+\\.tf$";
          pass_filenames = false;
        };
        oxlint = {
          enable = true;
          name = "oxlint";
          entry = "${pkgs.oxlint}/bin/oxlint --type-aware";
          files = "\\.(ts|tsx|js|jsx)$";
          pass_filenames = false;
        };
        workflow-timeout = {
          enable = true;
          name = "Check workflow timeout-minutes";
          package = pkgs.check-jsonschema;
          entry = "${pkgs.check-jsonschema}/bin/check-jsonschema --builtin-schema github-workflows-require-timeout";
          files = "\\.github/workflows/.*\\.ya?ml$";
        };

      };
    };
}
