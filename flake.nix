{
  description = "flux manifests repo with pre-commit hooks";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };
  outputs = {
    self,
    nixpkgs,
    git-hooks,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    checks.${system}.pre-commit-check = git-hooks.lib.${system}.run {
      src = ./.;
      hooks = {
        check-yaml.enable = true;
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
    devShells.${system}.default = pkgs.mkShell {
      inherit (self.checks.${system}.pre-commit-check) shellHook;
      buildInputs = with pkgs;
        [
          conftest
          kube-linter
          kustomize
        ]
        ++ self.checks.${system}.pre-commit-check.enabledPackages;
    };
  };
}
