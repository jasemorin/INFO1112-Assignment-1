#!/bin/bash
DEBUG=0
# --- Helper functions ---
die() {
    echo "assembler: $*"
    exit 1
}

decToBin() {
    local tmp bit weight n

    [[ "$1" =~ ^[0-9]+$ ]] || die "Internal error: decToBin needs a number, got: '$1'"
    n=$((10#$1)) # parse as dec
    ((n <= 255)) || die "Internal error: decToBin out of range [0, 255]: $1"

    membin=""
    tmp=$n
    for weight in 128 64 32 16 8 4 2 1; do
        if (($tmp >= $weight)); then
            bit=1
            tmp=$(($tmp - $weight))
        else
            bit=0
        fi
        membin="$membin$bit"
    done
}

binToHex() {
    # %02x -> at least two digits, 0 padding, hex; 2# -> bin number
    [[ "$1" =~ ^[01]{8}$ ]] || die "Internal error: binToHex needs 8 bits, got: '$1'"
    printf '%02x' "$((2#$1))"
}

# --- 1. Check arguments ---------------------------------------
# Check one argument provided
[[ $# -ne 1 ]] && die "Usage: $0 <file.vsc>"

# Check argument file extension
[[ ! "$1" == *.vsc ]] && die "Error: File must have .vsc extension: $1"

# Check if file exists
[[ ! -f "$1" ]] && die "Error: File not found: $1"

# Check empty argument
[[ -z "$1" ]] && die "Usage: $0 <file.vsc>"

# --- 2. Read file ---------------------------------------------
lines=()

while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}" # removes \r - CRLF compatibility
    lines+=("$line")
done <"$1"

# for debug **********************************
if ((DEBUG)); then
    echo "There are ${#lines[@]} lines in total"
    for i in "${!lines[@]}"; do
        echo " [$i] line $((i + 1)): ${lines[i]}"
    done
fi
# ********************************************

# --- 3. Check file structure -----------------------------------
# file is empty: warn and exit
((${#lines[@]} == 0)) && die "Warning: $1 is empty, no .bin file produced."

# check firstline: 0->QUIT; 2->ADDSUB; other->Error
if [[ "${lines[0]}" == "0" ]]; then
    program_type="QUIT"
elif [[ "${lines[0]}" == "2" ]]; then
    program_type="ADDSUB"
else
    die "Error: File line 1 must be 0 or 2: $1"
fi

# for debug **********************************
if ((DEBUG)); then
    echo "program_type=$program_type"
fi
# ********************************************

# --- 4. QUIT branch -----------------------------------------------
if [[ $program_type == "QUIT" ]]; then
    echo "It is a QUIT program"

    # check: total line number must be 2 and line two must be QUIT,0,0
    ((${#lines[@]} != 2)) && die "Error: file must only have two lines: $1"
    [[ ${lines[1]} != "QUIT,0,0" ]] && die "Error: file must contain instruction \"QUIT,0,0\" only"

    outfile="${1%.vsc}.bin"

    # clear and create outfile
    : >"$outfile" # clear

    # write two bytes
    printf '\x20' >>"$outfile"
    printf '\x00' >>"$outfile"

    # print output (fixed)
    echo "***********"
    echo "The content of the .bin file is:"
    echo "20"
    echo "00"

    exit 0
fi

# --- 5. ADD/SUB static data check ------------------------------------
if [[ $program_type == "ADDSUB" ]]; then
    echo "It is an ADD/SUB program"
    echo "-----------"

    dataArray=()

    # minimum number of lines is 4
    ((${#lines[@]} < 4)) && die "Error: file is incomplete: $1 (check data and instruction)"

    # verify line two and three, and store
    for i in 1 2; do
        val="${lines[i]}"
        # verify type is number
        ! [[ "$val" =~ ^[0-9]+$ ]] && die "Error: file has non-number data: $1"
        # normalise
        val=$((10#$val))
        # verify range
        ! ((val >= 0 && val < 128)) && die "Error: file data must be within range [0, 128): $1"
        # store in hex
        decToBin "$val"
        dataArray+=("$(binToHex "$membin")")
    done

# --- 6. instruction loop ------------------------------------------------
found_quit=0
count=0

for ((i = 3; i < ${#lines[@]}; i++)); do
    line="${lines[i]}"
    lineno=$((i + 1))

    # assumption: QUIT,0,0 counts towards the 100 instruction capacity
    ((count >= 100)) && die "Error: file exceeds max number of instructions (100): $1"

    # check length
    ((${#line} > 11)) && die "Error: line exceeds max length (11): $lineno"

    # cut
    IFS=, read -r ins reg mem <<<"$line"

    # match and verify opcode
    case "$ins" in
    LOAD)
        opcode=1
        ;;
    STORE)
        opcode=2
        ;;
    ADD)
        opcode=3
        ;;
    SUB)
        opcode=4
        ;;
    QUIT)
        opcode=8
        ;;
    PRINT)
        opcode=9
        ;;
    *)
        die "Error: Line has invalid opcode: $lineno"
        ;;
    esac

    # verify reg: digits only (also rejects empty), then range [0,3]
    [[ "$reg" =~ ^[0-9]+$ ]] || die "Error: line $lineno has invalid reg: '$reg'"
    reg=$((10#$reg))
    ((reg <= 3)) || die "Error: line $lineno reg must be within [0,3]: $reg"

    # verify mem: digits only (also rejects empty and '1,2'), then range [0,255]
    [[ "$mem" =~ ^[0-9]+$ ]] || die "Error: line $lineno has invalid mem: '$mem'"
    mem=$((10#$mem))
    ((mem <= 255)) || die "Error: line $lineno mem must be within [0,255]: $mem"

    # byte 1 = 6 bits opcode + 2 bits reg; byte 2 = 8 bits mem
    # membin is global, so read it straight after each decToBin call
    decToBin "$opcode"
    opbin="${membin:2}"
    decToBin "$reg"
    regbin="${membin:6}"
    byte1="$opbin$regbin"
    decToBin "$mem"
    byte2="$membin"

    dataArray+=("$(binToHex "$byte1")" "$(binToHex "$byte2")")

    if [[ "$line" == "QUIT,0,0" ]]; then
        found_quit=1
        echo "Found the <QUIT> so ending the conversion procedure ....."
        break
    fi

    count=$((count + 1))
    echo "Line $lineno: $line ..... <VALID>"
done

((found_quit == 0)) && die "Error: File has no QUIT instruction: $1"

# --- 7. write out -------------------------------------------------------
outfile="${1%.vsc}.bin"
: >"$outfile" # clear / create

echo ""
echo "***********"
echo "Done with the conversion"
echo "The content of the .bin file is:"
for b in "${dataArray[@]}"; do
    printf "\\x$b" >>"$outfile"
    echo "$b"
done
fi
