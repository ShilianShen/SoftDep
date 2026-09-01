#!/usr/bin/env bash
set -e

rm -f luacov.stats.out luacov.report.out
busted spec/lua -c
luacov
rm -f luacov.stats.out luacov.report.out