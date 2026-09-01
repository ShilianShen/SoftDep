#!/usr/bin/env bash
set -e

mkdir -p coverage
rm -f coverage/luacov.stats.out
rm -f coverage/lcov.info

busted spec/lua -c
luacov -r lcov