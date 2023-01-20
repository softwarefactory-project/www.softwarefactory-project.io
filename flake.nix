{
  description = "sf.io site builder flake";
  inputs = { nixpkgs.url = "github:nixos/nixpkgs/22.11"; };

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux.pkgs;
      buildScript = pkgs.writeScriptBin "build-site.sh" ''
        #!/bin/sh

        pushd src
        ./blog-htmx.sh
        ./blog-practical-haskell-use-cases.sh
        ./blog-introducing-effects.sh
        ./blog-introducing-functional-programming-to-pythonistas.sh
        ./blog-sf-resources-in-reason.sh
        ./blog-nix-shell.sh
        ./blog-nix-shell-flakes.sh
        popd

        pushd website
        pelican content -o output
        popd
      '';
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        name = "Website toolings shell";
        buildInputs = [ pkgs.pandoc pkgs.python39Packages.pelican buildScript ];
        shellHook = ''
          echo "Welcome in the nix shell for $name"
          echo "Run the build-site.sh command to build the website in website/output"
          echo "Then run: firefox website/output/index.html"
        '';
      };
    };
}
