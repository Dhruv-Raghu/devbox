{
  description = "Reproducible developer tooling for devbox";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      tools = with pkgs; [
        bat
        btop
        fd
        fzf
        gh
        git
        jq
        just
        mise
        nixd
        ripgrep
        shellcheck
        tmux
        tree
        uv
        yq-go
      ];
    in {
      packages.${system}.devbox-tools = pkgs.buildEnv {
        name = "devbox-tools";
        paths = tools;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = tools;
      };

      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
