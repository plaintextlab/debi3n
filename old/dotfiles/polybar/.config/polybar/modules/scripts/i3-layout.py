#!/usr/bin/env python3
# i3-layout.py -- robust layout detector for Polybar
# Prints one-line polybar-formatted chip: icon + label.
# Recognizes tabbed, stacked/stacking, and split* (splith/splitv).
#
# Usage: exec this from Polybar with interval=1

import json, subprocess, sys
from shutil import which

# ---------- Appearance (adjust if you like) ----------
COLOR_BG = "#3c3836"
COLOR_TILE = "#8ec07c"
COLOR_STACK = "#fabd2f"
COLOR_TAB  = "#b8bb26"

ICON_TILE  = ""
ICON_STACK = ""
ICON_TAB   = "󰓩"

#LABEL_TILE  = "Tile"
#LABEL_STACK = "Stack"
#LABEL_TAB   = "Tab"
LABEL_TILE  = ""
LABEL_STACK = ""
LABEL_TAB   = ""
# -----------------------------------------------------

def get_tree():
    if which("i3-msg") is None:
        print("i3-msg not found", file=sys.stderr); sys.exit(1)
    p = subprocess.run(["i3-msg", "-t", "get_tree"], capture_output=True, text=True)
    if p.returncode != 0:
        print("i3-msg failed: " + p.stderr.strip(), file=sys.stderr); sys.exit(1)
    return json.loads(p.stdout)

def find_path_to_focused(node, path=None):
    if path is None: path = []
    cur = path + [node]
    if node.get("focused", False):
        return cur
    for key in ("nodes", "floating_nodes"):
        for child in node.get(key, []):
            res = find_path_to_focused(child, cur)
            if res:
                return res
    return None

def main():
    tree = get_tree()
    path = find_path_to_focused(tree)
    chosen = None

    if path:
        # walk from focused node up towards root; pick first ancestor that is tabbed or stacked/stacking
        for node in reversed(path):
            layout = node.get("layout", "")
            if layout == "tabbed" or layout in ("stacked", "stacking"):
                chosen = layout
                break

    # decide output
    if chosen == "tabbed":
        fg = COLOR_TAB; icon = ICON_TAB; label = LABEL_TAB
    elif chosen in ("stacked", "stacking"):
        fg = COLOR_STACK; icon = ICON_STACK; label = LABEL_STACK
    else:
        fg = COLOR_TILE; icon = ICON_TILE; label = LABEL_TILE

    out = "%%{B%s}%%{F%s}  %s %s  %%{B-}%%{F-}" % (COLOR_BG, fg, icon, label)
    print(out)

if __name__ == "__main__":
    main()
