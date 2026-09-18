#! /bin/bash

# ---- helper functions -------------------------
# NOTE: the pointers doc says error messages go to STDOUT (not STDERR).
# That is unusual, so it is isolated here: if Ed confirms STDERR, add >&2 back
# in this one place and the whole script follows.
die() { echo "assembler: $*"; exit 1; }


# ---- 1. Check arguments -----------------------
# check 1 argument is provided
[ ! $# -eq 1 ] && die "Usage: $0 <file.vsc>"

# check if file has .vsc extension
[[ ! "$1" =~ \.vsc$ ]] && die "Error: File must have .vsc extension: $1"
[ ! -f "$1" ] && die "Error: File not found: $1"


# ---- 2. Read every line into an array ---------
# Store lines *including* blank ones, so that the array index maps directly to
# the real line number:  lines[0] is line 1, lines[3] is line 4, etc.
# The output format requires printing "Line 4: ..." so the mapping must hold.
lines=()

# builtin read command reads from stdin until next \n, storing to $line and dropping \n.
while IFS= read -r line || [ -n "$line" ]; do   # IFS temporarily set to "" so no trimming/splitting; -r keeps backslashes raw; || runs RHS if read failed, rescuing a final line with no trailing newline
  line="${line%$'\r'}"                          # tolerate files saved with Windows CRLF endings
  lines+=("$line")
done < "$1"       # redirect instead of piping: a pipe would run the loop in a subshell and lose the array

n_lines=${#lines[@]}


# ---- 3. Validate the overall file structure ---
# an empty file: warn, produce no .bin
(( n_lines == 0 )) && die "Warning: $1 is empty, no .bin file produced."

first="${lines[0]}"

# Line 1 must be exactly "0" or "2" (the only two program shapes in this spec)
if [ "$first" = "0" ]; then
  program_type="QUIT"
elif [ "$first" = "2" ]; then
  program_type="ADDSUB"
else
  die "Error: line 1 must be 0 or 2, got: $first"
fi


# ---- 4. Dispatch ------------------------------
if [ "$program_type" = "QUIT" ]; then
  echo "It is a QUIT program"
  # TODO: line 2 must be exactly QUIT,0,0  -> bytes 20 00
else
  echo "It is an ADD/SUB program"
  echo "-----------"
  # TODO: lines 2 and 3 are static data; line 4 onward are instructions
fi
