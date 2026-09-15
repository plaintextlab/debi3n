#!/bin/sh
# ~/.local/bin/nsxiv-open
dir=$(dirname -- "$1")
file=$(basename -- "$1")
cd -- "$dir" || exit 1

# build sorted list of images in this dir
set -- *.jpg *.jpeg *.png *.gif *.webp *.bmp

n=1
i=1
for f in "$@"; do
    [ "$f" = "$file" ] && n=$i
    i=$((i + 1))
done

exec nsxiv -n "$n" -- "$@"
