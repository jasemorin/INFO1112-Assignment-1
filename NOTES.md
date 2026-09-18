# VSC 参考卡 / Reference card

从 PDF 抄下来的硬事实。写代码时对着这张卡查。

## Opcode 表 (Figure 2)

| 助记符 | opcode | 二进制 | reg 字段 | addr 字段 |
|---|---|---|---|---|
| LOAD  | 1 | 000001 | 用 | 用 |
| STORE | 2 | 000010 | 用 | 用 |
| ADD   | 3 | 000011 | 用 | 用 |
| SUB   | 4 | 000100 | 用 | 用 |
| QUIT  | 8 | 001000 | 00（忽略） | 00000000（忽略） |
| PRINT | 9 | 001001 | 用 | 00000000（忽略） |

注意 opcode **不是** 1,2,3,4,5,6 —— QUIT 直接跳到 8，PRINT 是 9。

## 位布局 (Figure 1)

```
 bit: 15 14 13 12 11 10 | 9  8 | 7 6 5 4 3 2 1 0
      └──── opcode ────┘ └reg─┘ └───── addr ────┘
      ←———— 字节 hi ————————→ ←——— 字节 lo ———→

编码:  hi = (opcode << 2) | reg        lo = addr
解码:  opcode = hi >> 2   reg = hi & 3   addr = lo
```

## .vsc 文件格式 (Figure 3 + 4)

```
第 1 行        : n_values          有几个静态数据
接下来 n 行    : 静态数据           依次装进内存地址 0 .. n_values-1
之后每一行     : MNEMONIC,reg,addr  逗号分隔，一行一条指令
```

## .bin 文件格式 (Figure 3)

**不是 256 字节镜像**，是紧凑格式：

```
偏移 0            : n_values                    1 字节
偏移 1 .. n       : 静态数据                     n_values 字节
偏移 1+n .. 末尾  : 指令，每条 2 字节             直到文件结束
```

## 装载规则（emulator 怎么把 .bin 变成内存）

```
memory[i] = filebyte[i + 1]      # 跳过开头那个 n_values 字节
PC = n_values                    # 这就是 spec 里的 N
```

文件偏移和内存地址差 1，因为文件开头多了个 n_values 字节。**这是最容易搞错的一点。**

## Golden test：PDF 官方例子 (tests/prog1.vsc)

源文件：
```
2
20
40
LOAD,0,0
ADD,0,1
STORE,0,14
PRINT,0,0
QUIT,0,0
```

汇编后 prog1.bin 应该是 **13 个字节**：

| 文件偏移 | 值 | 内存地址 | 含义 |
|---|---|---|---|
| 0  | 2  | —  | n_values |
| 1  | 20 | 0  | 静态数据 |
| 2  | 40 | 1  | 静态数据 |
| 3  | 4  | 2  | LOAD hi  = (1<<2)\|0 |
| 4  | 0  | 3  | LOAD lo  = 0 |
| 5  | 12 | 4  | ADD hi   = (3<<2)\|0 |
| 6  | 1  | 5  | ADD lo   = 1 |
| 7  | 8  | 6  | STORE hi = (2<<2)\|0 |
| 8  | 14 | 7  | STORE lo = 14 |
| 9  | 36 | 8  | PRINT hi = (9<<2)\|0 |
| 10 | 0  | 9  | PRINT lo = 0 |
| 11 | 32 | 10 | QUIT hi  = (8<<2)\|0 |
| 12 | 0  | 11 | QUIT lo  = 0 |

验证命令：
```bash
od -An -v -tu1 -w1 tests/prog1.bin | tr -d ' ' | tr '\n' ' '
# 应该输出: 2 20 40 4 0 12 1 8 14 36 0 32 0
```

## 执行轨迹（emulator 应该走出这个过程）

| PC | hi,lo | 译码 | 动作 | R0 |
|---|---|---|---|---|
| 2  | 4,0   | 4>>2=1 LOAD R0,[0]   | R0 ← mem[0]=20 | 20 |
| 4  | 12,1  | 12>>2=3 ADD R0,[1]   | R0 ← 20+40     | 60 |
| 6  | 8,14  | 8>>2=2 STORE R0,[14] | mem[14] ← 60   | 60 |
| 8  | 36,0  | 36>>2=9 PRINT R0     | 打印 60         | 60 |
| 10 | 32,0  | 32>>2=8 QUIT         | 停机            | —  |

最终输出：`60`

## 还需要问助教的（spec 没写）

1. ADD 溢出：`200+100=300` 超过 1 字节，截断成 `% 256` 还是报错？
2. SUB 失败时错误信息的具体格式有要求吗？stdout 还是 stderr？
3. PRINT 输出是十进制吗？后面要不要换行？

## die()
Helper function. Breaking it down:


die() { echo "assembler: $*" >&2; exit 1; }
#  ^      ^                  ^     ^
#  |      |                  |     └─ exit with failure status
#  |      |                  └─ send to stderr, not stdout
#  |      └─ all arguments, joined with spaces
#  └─ function definition
$* — every argument you passed, as one string. So die "File not found: $src" prints assembler: File not found: sample.vsc. ($@ would be the same here; $* is the conventional choice for message-joining.)
>&2 — writes to file descriptor 2 (stderr) instead of 1 (stdout). Error messages belong on stderr so they don't get mixed into your program's real output if someone pipes it.
exit 1 — stops the script with a non-zero status, which means "failed". exit 0 means success.