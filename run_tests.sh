#!/usr/bin/env bash
# 对 tests/ 里每个 .vsc：汇编 -> 执行 -> 和 .expected 比对
set -u
pass=0; fail=0
for vsc in tests/*.vsc; do
    base="${vsc%.vsc}"
    if ! bash assembler.sh "$vsc" >/dev/null 2>&1; then
        echo "FAIL $base  (assembler 非 0 退出)"; ((fail++)); continue
    fi
    actual=$(bash emulator.sh "$base.bin" 2>&1)
    expected=$(cat "$base.expected")
    if [[ "$actual" == "$expected" ]]; then
        echo "PASS $base"; ((pass++))
    else
        echo "FAIL $base"
        diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") | sed 's/^/      /'
        ((fail++))
    fi
done
echo "---- $pass passed, $fail failed ----"
(( fail == 0 ))
