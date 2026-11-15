#!/bin/bash
# SPDX-FileCopyrightText: 2026 Taro Suzuki
# SPDX-FileCopyrightText: 2026 Shoma Sato
# SPDX-License-Identifier: BSD-3-Clause

res=0

ng() {
    echo "失敗: $1" >&2
    res=1
}

# 一時フォルダーを作り、終了時に削除する
tmpdir=$(mktemp -d) || exit 1
trap 'rm -rf -- "$tmpdir"' EXIT

# 終了ステータス・標準出力・標準エラー出力を確認する
check() {
    name="$1"
    input="$2"
    expected_status="$3"
    expected_output="$4"
    expected_error="$5"
    shift 5

    printf '%s' "$input" |
        ./timegap "$@" > "$tmpdir/out" 2> "$tmpdir/err"
    status=$?

    [ "$status" -eq "$expected_status" ] ||
        ng "$name: 終了ステータス"

    printf '%s' "$expected_output" > "$tmpdir/expected"
    cmp -s "$tmpdir/out" "$tmpdir/expected" ||
        ng "$name: 標準出力"

    printf '%s' "$expected_error" > "$tmpdir/expected"
    cmp -s "$tmpdir/err" "$tmpdir/expected" ||
        ng "$name: 標準エラー出力"
}

check "通常の間隔" \
    $'12:00:00\n12:00:03\n12:00:10\n12:01:00\n' \
    0 $'3\n7\n50\n' ''

check "同じ時刻" \
    $'12:00:00\n12:00:00\n' \
    0 $'0\n' ''

check "時をまたぐ間隔" \
    $'12:59:59\n13:00:01\n' \
    0 $'2\n' ''

check "空の入力" \
    '' 0 '' ''

check "時刻が1つだけ" \
    $'12:00:00\n' 0 '' ''

check "末尾に改行がない入力" \
    $'12:00:00\n12:00:03' \
    0 $'3\n' ''

check "不正な形式" \
    $'abc\n' \
    1 '' $'1行目: 時刻はHH:MM:SS形式で入力してください\n'

check "空行" \
    $'\n' \
    1 '' $'1行目: 時刻はHH:MM:SS形式で入力してください\n'

check "時の範囲外" \
    $'25:00:00\n' \
    1 '' $'1行目: 時刻の範囲が正しくありません\n'

check "分の範囲外" \
    $'12:60:00\n' \
    1 '' $'1行目: 時刻の範囲が正しくありません\n'

check "秒の範囲外" \
    $'12:00:60\n' \
    1 '' $'1行目: 時刻の範囲が正しくありません\n'

check "時刻の逆戻り" \
    $'12:00:10\n12:00:03\n' \
    1 '' $'2行目: 時刻が逆戻りしています\n'

check "途中で不正な入力" \
    $'12:00:00\n12:00:03\nabc\n' \
    1 $'3\n' $'3行目: 時刻はHH:MM:SS形式で入力してください\n'

check "不要な引数" \
    '' 1 '' $'使い方: timegap < times.txt\n' extra

[ "$res" -eq 0 ] && echo "OK"
exit "$res"
