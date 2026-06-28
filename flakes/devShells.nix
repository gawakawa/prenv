_: {
  perSystem =
    { config, pkgs, ... }:
    let
      devPackages =
        config.pre-commit.settings.enabledPackages
        ++ (with pkgs; [
          go
          google-cloud-sdk
          opentofu
          terraform-docs
          pnpm_10
          nodejs_24
        ]);
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs = devPackages;

        shellHook = ''
          ${config.pre-commit.shellHook}
        '';
      };
    };
}
