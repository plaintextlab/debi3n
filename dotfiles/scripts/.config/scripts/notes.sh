#!/usr/bin/env bash
# notes.sh — browse and open notes with fzf + micro
# Usage:
#   notes.sh          → fzf picker, open selected note in micro
#   notes.sh --new    → prompt for a filename and open a new note
NOTES_DIR="$HOME/Notes"
SYNC_SCRIPT="$NOTES_DIR/.sync"
mkdir -p "$NOTES_DIR"

new_note() {
    FILENAME=$(echo "" | \
        fzf --print-query \
            --prompt="New note name (no extension): " \
            --header="Press Enter to confirm, Esc to cancel" \
            --no-info \
            --height=5 \
        | head -1)
    [[ -z "$FILENAME" ]] && exit 0
    FILENAME="${FILENAME%.md}"
    FILEPATH="$NOTES_DIR/${FILENAME}.md"
    mkdir -p "$(dirname "$FILEPATH")"
    exec micro "$FILEPATH"
}

open_note() {
    SELECTED=$(find -L "$NOTES_DIR" -type f -name "*.md" -printf '%P\n' | \
        sed 's|\.md$||' | \
        sort | \
        fzf \
            --prompt="Notes > " \
            --preview="cat $NOTES_DIR/{}.md" \
            --preview-window=right:60%:wrap \
            --bind='ctrl-/:toggle-preview' \
            --bind="ctrl-s:execute(bash -c '\"$SYNC_SCRIPT\"; echo; read -n1 -r -p \"Press any key to return...\"')" \
            --header="Enter: open  |  Ctrl-/: preview  |  Ctrl-S: sync  |  Esc: quit" \
            --height=80% \
            --border=none \
            --info=inline \
        )
    [[ -z "$SELECTED" ]] && exit 0
    exec micro "$NOTES_DIR/${SELECTED}.md"
}

case "${1:-}" in
    --new|-n) new_note ;;
    *)        open_note ;;
esac
