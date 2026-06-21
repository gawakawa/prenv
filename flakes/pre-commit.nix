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
        terraform-docs-shared = {
          enable = true;
          entry = "${pkgs.terraform-docs}/bin/terraform-docs terraform/shared";
          files = "^terraform/shared/[^/]+\\.tf$";
          pass_filenames = false;
        };
        terraform-docs-pr = {
          enable = true;
          entry = "${pkgs.terraform-docs}/bin/terraform-docs terraform/env/pr";
          files = "^terraform/env/pr/.*\\.tf$";
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
