#!/usr/bin/env sh

# Convert the CI var.yml file to a file that can be included by a Makefile

tmpfile=$(mktemp)
grep ': ' $1 | sed 's/: / = /g' >"$tmpfile"
echo "$tmpfile"
