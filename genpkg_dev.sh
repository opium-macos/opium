#!/usr/bin/env bash

## Update LIBEXEC inside the script (not the best way...)
sed -E -i '' 's/LIBEXEC="\.\.\/libexec"/LIBEXEC="src\/genpkg\/libexec"/g' src/genpkg/genpkg

## Linking getpath into libexec
ln -s src/utils/getpath/getpath src/genpkg/libexec

./src/genpkg/genpkg "$@"

## Unlinking getpath into libexec
rm src/genpkg/libexec/getpath

## Restore LIBEXEC inside the script (not the best way...)
sed -E -i '' 's/LIBEXEC="src\/genpkg\/libexec"/LIBEXEC="\.\.\/libexec"/g' src/genpkg/genpkg
