#!/bin/bash

# Test script for FindUtils module

set -e

PASS=0
FAIL=0

run_test() {
  local desc="$1"
  local cmd="$2"
  if nvim --headless --cmd "set rtp+=." -c "$cmd" -c "q" 2>/dev/null; then
    echo "✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "❌ $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "Testing FindUtils..."

run_test "Module loads" \
  "lua require('FindUtils')"

run_test "find_all is a function" \
  "lua local m = require('FindUtils'); if type(m.find_all) ~= 'function' then os.exit(1) end"

run_test "find_buf is a function" \
  "lua local m = require('FindUtils'); if type(m.find_buf) ~= 'function' then os.exit(1) end"

run_test ":FindAll command registered" \
  "lua require('FindUtils'); if vim.fn.exists(':FindAll') == 0 then os.exit(1) end"

run_test ":FindBuf command registered" \
  "lua require('FindUtils'); if vim.fn.exists(':FindBuf') == 0 then os.exit(1) end"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ]
