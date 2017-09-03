#!/bin/bash
echo "Server starting"
source server.sh

while ! nc -z localhost 56789; do # check if deployserver is listening
  sleep 0.1 # wait for 1/10 of the second before check again
done
echo "Server started"

echo "Sending request"
source client.sh "localhost"