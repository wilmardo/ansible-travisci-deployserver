#!/bin/bash
role=$(printenv TRAVIS_REPO_SLUG | rev | cut -d "-" -f1 | rev) #reverse cut leaves last part of repo name which is role name

if [ "$DEPLOY_CREDENTIALS" ]; then
    http_status=$(curl -u $DEPLOY_CREDENTIALS --silent -ls -w "%{http_code}" -L $1/?$role -o /dev/null)
else
    http_status=$(curl --silent -ls -w "%{http_code}" -L $1/?$role -o /dev/null)
fi

if [[ $http_status == 200 ]]; then
    exit 0
else
    exit 1
fi