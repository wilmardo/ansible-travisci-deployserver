#!/bin/bash
url=$1
role=$(printenv TRAVIS_REPO_SLUG | rev | cut -d "-" -f1 | rev) #reverse cut leaves last part of repo name which is role name

exec 3>&1
if [ "$DEPLOY_CREDENTIALS" ]; then
    http_status=$(curl -u $DEPLOY_CREDENTIALS -v -s -w "%{http_code}" -o >(cat >&3) $url/?$role)
else
    http_status=$(curl -v -s -w "%{http_code}" -o >(cat >&3) $url/?$role)
fi

if [[ $http_status == 200 ]]; then
    exit 0
else
    exit 1
fi