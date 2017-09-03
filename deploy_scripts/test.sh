#!/bin/bash
# PASSED VARIABLES
nc=$1
command=$2

# TEST CASE FOR TRAVISCI
if [ "$command" == "deployserver" ]; then
    printf 'HTTP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n' >&"${nc[1]}"
    exit 0
else
    exit 1
fi