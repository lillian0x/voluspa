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
            alejandra.enable = true;
            check-yaml.enable = true;
            yamlfmt = {
              enable = true;
              settings.lint-only = false;
            };
            kube-linter = {
              enable = true;
              name = "kube-linter";
              entry = "${pkgs.writeShellScript "kube-linter-check" ''
                set -euo pipefail
                ${pkgs.kube-linter}/bin/kube-linter lint .
              ''}";
              language = "system";
              pass_filenames = false;
              files = "\\.ya?ml$";
            };
          };
        };
        formatter = pkgs.writeShellScriptBin "pre-commit-run" ''
          ${pkgs.lib.getExe config.pre-commit.settings.package} run --all-files --config ${config.pre-commit.settings.configFile}
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
