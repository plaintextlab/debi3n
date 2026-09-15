
#!/usr/bin/env bash
# /home/qube/.config/polybar/modules/mpris-visibility-manager.sh
PRODUCER="/home/qube/.config/polybar/modules/scripts/mpris-polybar.sh"
POLYBAR_MSG="$(command -v polybar-msg || true)"
MODULES=( "mpris-art" "mpris-text" "mpris-controls" )
SHOW_DEBOUNCE=0.35
HIDE_DEBOUNCE=0.5
visible=0

if [[ -z "$POLYBAR_MSG" ]]; then
  echo "polybar-msg not found" >&2
  exit 1
fi
if [[ ! -x "$PRODUCER" ]]; then
  echo "producer missing: $PRODUCER" >&2
  exit 1
fi

hide_modules() {
  for m in "${MODULES[@]}"; do
    "$POLYBAR_MSG" action "#${m}.module_hide" >/dev/null 2>&1 || true
  done
  visible=0
}

show_modules() {
  for m in "${MODULES[@]}"; do
    "$POLYBAR_MSG" action "#${m}.module_show" >/dev/null 2>&1 || true
  done
  visible=1
}

# initial state
first=$("$PRODUCER" | tail -n1 || true)
if [[ -z "$first" || "$first" == STATE\|NONE* ]]; then
  hide_modules
else
  show_modules
fi

# watch
while IFS= read -r line; do
  IFS='|' read -r STATE PLAYER STATUS SHOW ARTPATH URL <<< "$line"
  if [[ "$line" == STATE\|NONE* ]] || [[ -z "$SHOW" ]] || [[ "$STATUS" == "Stopped" ]]; then
    if [[ "$visible" -eq 1 ]]; then
      sleep "$HIDE_DEBOUNCE"
      latest=$("$PRODUCER" | tail -n1 || true)
      if [[ -z "$latest" || "$latest" == STATE\|NONE* || "$latest" == *"|Stopped|"* ]]; then
        hide_modules
      fi
    fi
  else
    if [[ "$visible" -eq 0 ]]; then
      sleep "$SHOW_DEBOUNCE"
      latest=$("$PRODUCER" | tail -n1 || true)
      if [[ -n "$latest" && "$latest" != STATE\|NONE* ]]; then
        show_modules
      fi
    fi
  fi
done < <( "$PRODUCER" )
