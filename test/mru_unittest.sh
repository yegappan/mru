#!/bin/bash

# Script to run unit-tests for the MRU Vim plugin

VIM=/usr/bin/vim
VIM_CMD="$VIM -N -u NONE -U NONE -i NONE"

$VIM_CMD -S unit_tests.vim

echo "MRU unit test results"
cat results.txt

echo
grep FAIL results.txt > /dev/null 2>&1
if [ $? -eq 0 ]
then
    echo "ERROR: Some test failed."
else
    echo "SUCCESS: All the tests passed."
fi

