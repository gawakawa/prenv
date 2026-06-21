_: {
  perSystem =
    { config, pkgs, ... }:
    let
      devPackages =
        config.pre-commit.settings.enabledPackages
        ++ (with pkgs; [
          opentofu
          terraform-docs
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
