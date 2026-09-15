#!/usr/bin/env bash
# i3-layout-single-daemon.sh
# Long-running polybar module that shows current i3 layout and reacts to clicks.
# It watches a small socket file at /tmp/i3-layout-click and accepts commands:
#   1 -> tile, 2 -> stack, 3 -> tab
#
# Make sure polybar config writes clicks into /tmp/i3-layout-click (see below).

I3MSG=$(command -v i3-msg) || { echo "i3-msg not found"; exit 1; }
JQ=$(command -v jq) || { echo "jq not found"; exit 1; }

CLICK_FIFO="/tmp/i3-layout-click"
POLL=0.6    # seconds between UI refreshes

COLOR_BG="#3c3836"
COLOR_ACTIVE="#83a598"
COLOR_TEXT="#ebdbb2"

# icons & labels (change to glyphs you prefer)
ICON_TILE=""
ICON_STACK=""
ICON_TAB=""
LABEL_TILE="Tile"
LABEL_STACK="Stack"
LABEL_TAB="Tab"

TAB_CMD='layout tabbed'
STACK_CMD='layout stacking'
TILE_CMD='layout default'   # change if needed

# Ensure FIFO exists (we'll use a regular file for atomic writes)
# We'll accept either FIFO or simple file writes; using a small file is simplest.
touch "$CLICK_FIFO"
chmod 600 "$CLICK_FIFO"

# helper: read focused layout
get_layout() {
  # use i3-msg tree introspection to find focused node layout
  layout=$($I3MSG -t get_tree | $JQ -r '.. | select(.focused?==true) | .layout' 2>/dev/null | head -n1)
  echo "$layout"
}

# helper: perform click action
do_action() {
  cmd="$1"
  case "$cmd" in
    1) $I3MSG "$TILE_CMD" >/dev/null 2>&1 ;;
    2) $I3MSG "$STACK_CMD" >/dev/null 2>&1 ;;
    3) $I3MSG "$TAB_CMD" >/dev/null 2>&1 ;;
  esac
  # give i3 a moment
  sleep 0.06
}

# main loop: continuously print one-line output for polybar
# polybar expects continuous stdout; we will overwrite the line each loop
# Print full line followed by newline.
while true; do
  # If click file contains something, consume and act (use atomic read+truncate)
  if [ -s "$CLICK_FIFO" ]; then
    # read first byte/number
    cmd=$(head -c 4 "$CLICK_FIFO" | tr -d '\n' | tr -d '\r' | tr -d ' ')
    # clear file
    : > "$CLICK_FIFO"
    case "$cmd" in
      1|2|3)
        do_action "$cmd"
        ;;
      *)
        # ignore invalid
        ;;
    esac
  fi

  layout=$(get_layout)

  # determine icon + label + fg
  case "$layout" in
    tabbed)
      ICON="$ICON_TAB"; LABEL="$LABEL_TAB"; FG="$COLOR_ACTIVE"
      ;;
    stacking)
      ICON="$ICON_STACK"; LABEL="$LABEL_STACK"; FG="$COLOR_ACTIVE"
      ;;
    split*|splith|splitv|"")
      ICON="$ICON_TILE"; LABEL="$LABEL_TILE"; FG="$COLOR_ACTIVE"
      ;;
    *)
      ICON="$ICON_TILE"; LABEL="$LABEL_TILE"; FG="$COLOR_ACTIVE"
      ;;
  esac

  # Print one line for polybar
  printf "%%{B%s}%%{F%s}  %s %s  %%{B-}%%{F-}\n" "$COLOR_BG" "$FG" "$ICON" "$LABEL"

  sleep "$POLL"
done
