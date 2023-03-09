#!/bin/sh -e

NAME="blog-operator-monocle"

pandoc --include-in-header=./$NAME.rst \
       -f gfm --reference-links  \
       -t rst ./$NAME.md -o ../website/content/$NAME.rst

sed -e 's|^.. code::|.. code-block::|' -i ../website/content/$NAME.rst
