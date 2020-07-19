#!/bin/sh -e
converter=~/git/github.com/TristanCacqueray/haskell-playground/PandocProcessor.hs
dst=../website/content/blog-haskell-for-python-dev.rst
$converter --side-by-side-code-table ./blog-haskell-for-python-dev.md ./blog-haskell-for-python-dev.rst $dst
