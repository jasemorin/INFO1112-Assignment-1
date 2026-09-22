#!/bin/bash
# --- Helper functions ---
die() { echo "assembler: $*"; exit 1; }

# --- 1. Check arguments ---
# Check one argument provided
[ "$#" -ne 1 ] && die "Usage: $0 <file.vsc>"

# Check argument file extension
[[ ! "$1" == *.vsc ]] && die "Error: File must have .vsc extension: $1"

# Check if file exists
[ ! -f "$1" ] && die "Error: File not found: $1"

# --- 2. Read file ---
lines=()

while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"     # removes \r - CRLF compatibility
    lines+=("$line")
done < "$1"

echo "There are ${#lines[@]} lines in total"
for i in "${!lines[@]}"; do
    echo " [$i] line $((i+1)): ${lines[i]}"
done

