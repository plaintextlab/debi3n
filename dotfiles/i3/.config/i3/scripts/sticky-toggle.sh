#!/bin/bash
i3-msg sticky toggle > /dev/null

node=$(i3-msg -t get_tree | jq -c '[.. | objects | select(.focused==true)][0] // {}')
sticky=$(echo "$node" | jq -r '.sticky // false')
name=$(echo "$node" | jq -r '.name // "Unknown window"')

if [ "$sticky" = "true" ]; then
    notify-send -u low -i view-pin "Sticky window" "$name pinned to all workspaces"
else
    notify-send -u low -i window-close "Sticky window" "$name unpinned"
fi
