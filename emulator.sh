#!/usr/bin/env bash
# emulator.sh  —  假装自己是 VSC 这台 CPU，执行 .bin
# 用法: bash emulator.sh sample.bin
#
# ⚠️ 骨架文件。每个 TODO 都要你自己填。

set -u

die() { echo "emulator: $*" >&2; exit 1; }

# ---- 1. 检查参数 ----
# TODO: 恰好 1 个参数？文件存在？以 .bin 结尾？
bin=""

# ---- 2. 把整个文件读成一串十进制字节 ----
# mapfile -t raw < <(od -An -v -tu1 -w1 "$bin" | tr -d ' ')
#            ↑ -v 千万不能省！否则 od 会把连续重复的行折叠成 *，
#              内存里一堆 0 会被吃掉，而且不报错，只是结果莫名其妙不对。
# TODO

# ---- 3. 初始化机器状态 ----
# 内存 256 格全 0；寄存器 4 个全 0
# TODO
# for ((i=0; i<256; i++)); do mem[i]=0; done
# regs=(0 0 0 0)

# ---- 4. 装载：raw[0] 是 n_values，raw[1..] 依次进 mem[0..] ----
#      PC 起点 N = n_values
#      注意文件偏移比内存地址大 1
# TODO

# ---- 5. 主循环：fetch → decode → execute ----
# while :; do
#     (( pc >= 0 && pc + 1 < 256 )) || die "PC out of range: $pc"
#
#     hi=${mem[pc]}                 # FETCH
#     lo=${mem[$((pc+1))]}
#
#     op=$(( hi >> 2 ))             # DECODE
#     r=$((  hi & 3  ))
#     addr=$lo
#
#     case "$op" in                 # EXECUTE
#         1) : ;;   # TODO LOAD   regs[r] <- mem[addr]
#         2) : ;;   # TODO STORE  mem[addr] <- regs[r]
#         3) : ;;   # TODO ADD    regs[r] <- regs[r] + mem[addr]   (溢出？问助教)
#         4) : ;;   # TODO SUB    只有 regs[r] >= mem[addr] 才做；
#                   #             否则 stderr 报错、什么都不改、继续执行
#         8) break ;;               # QUIT
#         9) : ;;   # TODO PRINT  echo regs[r]
#         *) die "unknown opcode $op at address $pc" ;;
#     esac
#
#     pc=$(( pc + 2 ))              # 一条指令 2 字节
# done
