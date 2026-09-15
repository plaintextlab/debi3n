#!/bin/bash
# Check if any window in focused workspace is tiling
state=$(i3-msg -t get_tree | python3 -c "
import json, sys
tree = json.load(sys.stdin)
def get_focused_ws(node):
    for n in node.get('nodes', []) + node.get('floating_nodes', []):
        if n.get('type') == 'workspace' and n.get('focused'):
            return n
        result = get_focused_ws(n)
        if result:
            return result
ws = get_focused_ws(tree)
tiling = ws.get('nodes', []) if ws else []
print('tiling' if tiling else 'floating')
")

if [ "$state" = "tiling" ]; then
    i3-msg '[workspace=__focused__] floating enable'
else
    i3-msg '[workspace=__focused__] floating disable'
fi
