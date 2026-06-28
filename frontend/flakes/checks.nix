_: {
  perSystem =
    { pkgs, ... }:
    let
      pnpm = pkgs.pnpm_10;
      nodejs = pkgs.nodejs_24;
      src = ./..;

      pnpmDeps = pkgs.fetchPnpmDeps {
        pname = "pnpm-project-deps";
        version = "1.0.0";
        inherit src pnpm;
        fetcherVersion = 3;
        hash = "sha256-ME9Va1v3H0MBoH+JdVyVaHUy32FutzJqUrgq9kqS4dk=";
      };
    in
    {
      checks.tests = pkgs.stdenvNoCC.mkDerivation {
        name = "tests";
        inherit src pnpmDeps;

        nativeBuildInputs = [
          nodejs
          pkgs.pnpmConfigHook
          pnpm
        ];

        dontBuild = true;

        doCheck = true;
        checkPhase = ''
          runHook preCheck
          pnpm test
          runHook postCheck
        '';

        installPhase = ''
          runHook preInstall
          touch $out
          runHook postInstall
        '';
      };
    };
}
