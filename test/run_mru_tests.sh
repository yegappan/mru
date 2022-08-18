#!/bin/bash

# Script to run the unit-tests for the MRU Vim plugin

VIMPRG=${VIMPRG:=/usr/bin/vim}
VIM_CMD="$VIMPRG -N -u NONE -U NONE -i NONE --noplugin"

rm -f test.log

$VIM_CMD -S unit_tests.vim

if [ ! -f test.log ]
then
  echo "ERROR: Test results file 'test.log' is not found"
  exit 1
fi

echo "MRU unit test results:"
echo "====================="
cat test.log
echo

grep FAIL test.log > /dev/null 2>&1
if [ $? -eq 0 ]
then
  echo "ERROR: Some test(s) failed."
  exit 1
fi

echo "SUCCESS: All the tests passed."
exit 0
