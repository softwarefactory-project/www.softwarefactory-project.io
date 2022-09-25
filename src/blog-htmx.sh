#!/bin/sh -e

NAME="blog-htmx"

pandoc --include-in-header=./$NAME.rst \
       -f gfm --reference-links  \
       -t rst ./$NAME.md -o ../website/content/$NAME.rst

mkdir -p ../website/content/assets
cp assets/schat.png ../website/content/assets/

sed -e 's|^.. code::|.. code-block::|' -i ../website/content/$NAME.rst
