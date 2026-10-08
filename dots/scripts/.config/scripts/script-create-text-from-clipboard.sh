#!/bin/bash

# Generate a dynamic filename using the current date and time
# Format: backup_YYYY-MM-DD_HHMMSS.txt
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
OUTPUT_FILE="backup_${TIMESTAMP}.txt"

# Pasting multi-line content exactly as it is (Heredoc)
cat << 'EOF' > "$OUTPUT_FILE"
EOF

echo "Success! Dynamic file created: $OUTPUT_FILE"
