{
  description = "flux manifests repo with pre-commit hooks";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };
  outputs = inputs @ {
    flake-parts,
    systems,
    git-hooks,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import systems;
      imports = [
        git-hooks.flakeModule
      ];
      perSystem = {
        config,
        pkgs,
        ...
      }: {
        pre-commit.settings = {
          excludes = ["gotk-components\\.yaml$"];
          hooks = {
            alejandra = {
              enable = true;
              settings.verbosity = "quiet";
            };
            check-yaml.enable = true;
            yamlfmt = {
              enable = true;
              settings.lint-only = false;
            };
            kube-linter = {
              enable = true;
              name = "kube-linter";
              entry = "${pkgs.kube-linter}/bin/kube-linter lint .";
              excludes = ["clusters/\w{1,}/flux-system/gotk-components.yaml"];
              language = "unsupported";
              pass_filenames = false;
              files = "\\.ya?ml$";
            };
          };
        };
        formatter = let
          inherit (config.pre-commit.settings) configFile package;
        in
          pkgs.writeShellScriptBin "pre-commit-run" ''
            ${pkgs.lib.getExe package} run --all-files --config ${configFile}
          '';
        devShells.default = pkgs.mkShell {
          inherit (config.pre-commit) shellHook;
          buildInputs = with pkgs;
            [
              kustomize
              trivy
            ]
            ++ config.pre-commit.settings.enabledPackages;
        };
      };
    };
}
