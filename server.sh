#!/bin/bash
# SETUP
# git clone -n --depth 1 https://github.com/wilmardo/ansible-travisci-deployserver.git .
# git checkout HEAD server.sh deploy_scripts/
# Set environment variable DEPLOY_SCRIPT_NAME to sh script in use

# MAIN LOOP
# nc: coproc array with netcat server
# line: HTTP request per line
# command: parameter passed in the GET request

# CLEANUP
cleanup() {
    pkill -fx 'nc -lk 56789'
    exit 0
}

# EXIT TRAP
trap cleanup INT TERM EXIT

coproc nc { nc -lk 56789; }
while [[ $nc_PID ]] && IFS= read -ru ${nc[0]} line; do
    if [[ $line == "GET"* ]]; then
        command=$(echo $line | cut -d ' ' -f 2 | cut -c 3-) #split on space leaves /?role then cut first 2 chars off
        source deploy_scripts/$DEPLOY_SCRIPT_NAME $nc $command
    fi
done