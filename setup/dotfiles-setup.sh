#!/usr/bin/env bash

cd ~/debi3n/dots
stow -d . -t ~ */ 2>&1 | grep 'existing target' | sed -E 's/.*existing target is not owned by stow: //' | while read -r target; do
  echo "removing: $HOME/$target"
  rm -rf "$HOME/$target"
done

stow -d . -t ~ */