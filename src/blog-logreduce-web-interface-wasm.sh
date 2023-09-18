#! /usr/bin/env nix-shell
#! nix-shell -i bash -p nodePackages.mermaid-cli -p pandoc
#! nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/4d2b37a84fad1091b9de401eb450aae66f1a741e.tar.gz

NAME="blog-logreduce-web-interface-wasm"

mmdc -i blog-logreduce-web-interface-wasm.mmd -o ../website/content/images/logreduce-wasm-size.png

pandoc --include-in-header=./$NAME.rst \
       -f gfm --reference-links  \
       -t rst ./$NAME.md -o ../website/content/$NAME.rst

sed -e 's|^.. code::|.. code-block::|' -i ../website/content/$NAME.rst
