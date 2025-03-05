#!/bin/bash
set -e
set -x



make distclean
git checkout .
./tools/testing/kunit/kunit.py run --arch=riscv
