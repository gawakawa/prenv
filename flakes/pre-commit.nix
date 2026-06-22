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
          args = [ "--offline" ];
        };
        tflint.enable = true;
        terraform-docs-pr-base = {
          enable = true;
          entry = "${pkgs.terraform-docs}/bin/terraform-docs terraform/env/pr/base";
          files = "^terraform/env/pr/base/[^/]+\\.tf$";
          pass_filenames = false;
        };
        terraform-docs-pr-ephemeral = {
          enable = true;
          entry = "${pkgs.terraform-docs}/bin/terraform-docs terraform/env/pr/ephemeral";
          files = "^terraform/env/pr/ephemeral/[^/]+\\.tf$";
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
