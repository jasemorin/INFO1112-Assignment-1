#!/usr/bin/env bash
# assembler.sh  —  把 .vsc 文本翻译成 .bin 二进制
# 用法: bash assembler.sh sample.vsc   ->  产出 sample.bin
#

set -u

# exit with an error message
die() { echo "assembler: $*" >&2; exit 1; }

# ---- opcode 查表（数值见 NOTES.md 的 Figure 2 表） ----
declare -A OPCODE=(
    [LOAD]=1  [STORE]=2  [ADD]=3
    [SUB]=4   [QUIT]=8   [PRINT]=9
)

emit_byte() { printf "\\$(printf '%03o' "$1")"; }

# ---- 1. Argument Checks ----
# check if 1 argument is provided
[ $# -ne 1 ] && die "Usage: $0 <file.vsc>"
src="$1"
# check if file exists and has .vsc extension
[ ! -f "$src" ] && die "File not found: $src"
[[ "$src" != *.vsc ]] && die "File must have .vsc extension: $src"

# ---- 2. read all non-empty lines ----
# 提示: mapfile -t lines < "$src"
# TODO



# ---- 3. first line = n_values ----
# TODO: 取出来，检查是 0..255 的数字

# ---- 4. 接下来 n_values 行 = 静态数据 ----
# TODO: 每个检查 0..255，存进数组

# ---- 5. 剩下的行 = 指令，格式 MNEMONIC,reg,addr ----
# 提示: IFS=',' read -r mnem reg addr <<< "$line"
# TODO: 查 OPCODE 表；未知助记符要 die
#       检查 reg 在 0..3、addr 在 0..255
#       hi=$(( (op << 2) | reg ))   lo=$addr

# ---- 6. 按 .bin 格式写出：n_values, 静态数据..., 指令字节... ----
# out="${src%.vsc}.bin"
# TODO: 整个循环用一次重定向 > "$out"，别每个字节开一次文件
