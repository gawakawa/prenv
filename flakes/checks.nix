_: {
  perSystem =
    { pkgs, ... }:
    let
      pnpm = pkgs.pnpm_10;
      nodejs = pkgs.nodejs_26;
      src = ../frontend;

      pnpmDeps = pkgs.fetchPnpmDeps {
        pname = "pnpm-project-deps";
        version = "1.0.0";
        inherit src pnpm;
        fetcherVersion = 3;
        hash = "sha256-5WUENRDpIM6xO6ffUJMMr3zo+QdI4/cnXZlKtol2jT8=";
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
