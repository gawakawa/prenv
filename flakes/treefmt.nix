_: {
  perSystem = _: {
    treefmt = {
      programs = {
        terraform = {
          enable = true;
          includes = [
            "*.tf"
            "*.tfvars"
          ];
        };
        nixfmt = {
          enable = true;
          includes = [ "*.nix" ];
        };
      };
    };
  };
}
