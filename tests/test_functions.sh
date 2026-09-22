#!/bin/bash
# Unit tests for decToBin / binToHex.
# Sourcing assembler.sh with a valid ADD/SUB file runs sections 1-3 and then
# falls off the end, leaving the function definitions in this shell.
cd "$(dirname "$0")/.." || exit 1
source ./assembler.sh tests/add.vsc >/dev/null

pass=0; fail=0
check() {   # check <label> <expected> <actual>
    if [[ "$2" == "$3" ]]; then
        printf '  ok    %-22s -> %s\n' "$1" "$3"; pass=$((pass+1))
    else
        printf '  FAIL  %-22s -> got %-12s want %s\n' "$1" "${3:-<empty>}" "$2"; fail=$((fail+1))
    fi
}

echo "decToBin:"
for pair in "0 00000000" "12 00001100" "14 00001110" "127 01111111" "255 11111111"; do
    set -- $pair
    membin=""
    decToBin "$1"
    check "decToBin $1" "$2" "$membin"
done

echo "binToHex:"
for pair in "00000000 00" "00001100 0c" "00001110 0e" "01111111 7f" "11111111 ff" "00100000 20"; do
    set -- $pair
    check "binToHex $1" "$2" "$(binToHex "$1")"
done

echo
echo "passed $pass, failed $fail"
[[ $fail -eq 0 ]]
