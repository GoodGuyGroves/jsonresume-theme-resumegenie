{
  description = "Claude Code installation flake for project-local installation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Build claude-code directly using npm
        claude-code = pkgs.stdenv.mkDerivation {
          pname = "claude-code-local";
          version = "latest";
          
          src = null;
          
          nativeBuildInputs = with pkgs; [ nodejs nodePackages.npm ];
          
          unpackPhase = "true";
          
          buildPhase = ''
            export HOME=$TMPDIR
            export NPM_CONFIG_PREFIX=$out
            mkdir -p $out
            npm install -g @anthropic-ai/claude-code
          '';
          
          installPhase = "true"; # Already installed in buildPhase
          
          meta = with pkgs.lib; {
            description = "Claude Code - AI coding assistant";
            platforms = platforms.all;
          };
        };
      in
      {
        packages = {
          default = claude-code;
          claude-code = claude-code;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs
            nodePackages.npm
          ];
          
          shellHook = ''
            export NPM_CONFIG_PREFIX="$(pwd)/.npm-global"
            export PATH="$(pwd)/.npm-global/bin:$PATH"
            
            # Create the local npm directory if it doesn't exist
            mkdir -p .npm-global
            
            # Install claude-code if not already installed
            if [ ! -f ".npm-global/bin/claude" ]; then
              echo "Installing Claude Code locally to $(pwd)/.npm-global..."
              npm config set prefix "$(pwd)/.npm-global"
              npm install -g @anthropic-ai/claude-code
              echo "Claude Code installed! You can now use 'claude' command in this shell."
            else
              echo "Claude Code is already installed locally."
              echo "You can use the 'claude' command in this shell."
            fi
            
            # Add .npm-global to .gitignore if it's not already there
            if [ -f .gitignore ] && ! grep -q "^\.npm-global" .gitignore; then
              echo ".npm-global" >> .gitignore
              echo "Added .npm-global to .gitignore"
            elif [ ! -f .gitignore ]; then
              echo ".npm-global" > .gitignore
              echo "Created .gitignore with .npm-global"
            fi
          '';
        };

        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScript "claude-local" ''
            export NPM_CONFIG_PREFIX="$(pwd)/.npm-global"
            export PATH="$(pwd)/.npm-global/bin:$PATH"
            
            if [ ! -f ".npm-global/bin/claude" ]; then
              echo "Claude Code not found. Please run 'nix develop' first to install it."
              exit 1
            fi
            
            exec "$(pwd)/.npm-global/bin/claude" "$@"
          ''}";
        };
      });
}
