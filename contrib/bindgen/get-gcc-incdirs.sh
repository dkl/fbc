#!/bin/sh
echo | gcc -E -v - 2>&1 | ./parse-gcc-incdirs | while read ln; do
    echo "-I$ln"
done
