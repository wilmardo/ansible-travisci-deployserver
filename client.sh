#!/bin/bash
#TODO: Make one curl request and extract http code to prevent inconsistencies
role=$(printenv TRAVIS_REPO_SLUG | rev | cut -d "-" -f1 | rev) #reverse cut leaves last part of repo name which is role name

echo "Received role: $role"
if [ "$DEPLOY_CREDENTIALS" ]; then
    echo "DEPLOY_CREDENTIALS defined, sending basic auth request"
    http_status=$(curl -u $DEPLOY_CREDENTIALS -s -o /dev/null -I -w "%{http_code}" -L $1/?$role)
    curl -v -u $DEPLOY_CREDENTIALS $1/?$role
else
    echo "DEPLOY_CREDENTIALS undefined, sending request"
    http_status=$(curl -s -o /dev/null -I -w "%{http_code}" -L $1/?$role)
    curl -v -u $DEPLOY_CREDENTIALS $1/?$role
fi

echo "HTTP status: $http_status"
if [[ $http_status == 200 ]]; then
    exit 0
else
    exit 1
fi