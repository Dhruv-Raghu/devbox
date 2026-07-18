{
  description = "Reproducible developer tooling for devbox";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
      };
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
        nodejs_22
        python312
        ripgrep
        shellcheck
        tmux
        tree
        uv
        yq-go
        claude-code
        codex
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
