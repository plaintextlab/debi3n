#!/bin/bash
current=$(powerprofilesctl get)

case "$current" in
  performance)
  	powerprofilesctl set balanced
    echo "balanced"
    ;;
  balanced)
  	powerprofilesctl set power-saver
    echo "power-saver"
    ;;
  power-saver)
  	powerprofilesctl set performance
    echo "performance"
    ;;
esac
