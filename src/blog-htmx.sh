#!/bin/sh -e

NAME="blog-htmx"

pandoc --include-in-header=./$NAME.rst \
       -f gfm --reference-links  \
       -t rst ./$NAME.md -o ../website/content/$NAME.rst

cp images/schat.png ../website/content/images/

sed -e 's|^.. code::|.. code-block::|' -i ../website/content/$NAME.rst
