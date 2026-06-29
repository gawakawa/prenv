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
        gofmt = {
          enable = true;
          includes = [ "*.go" ];
        };
        goimports = {
          enable = true;
          includes = [ "*.go" ];
        };
        oxfmt = {
          enable = true;
          includes = [
            "*.ts"
            "*.tsx"
            "*.js"
            "*.jsx"
          ];
        };
      };
    };
  };
}
