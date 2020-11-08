#!/bin/sh -e

pandoc --include-in-header=./blog-sf-resources-in-reason.rst \
       -f gfm --reference-links  \
       -t rst ./blog-sf-resources-in-reason.md -o ../website/content/blog-sf-resources-in-reason.rst
