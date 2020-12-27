#!/bin/sh -e

NAME="blog-introducing-functional-programing-to-pythonistas"

pandoc --include-in-header=./$NAME.rst \
       -f gfm --reference-links  \
       -t rst ./$NAME.md -o ../website/content/$NAME.rst
