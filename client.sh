#!/bin/sh
role=$(printenv TRAVIS_REPO_SLUG | rev | cut -d "-" -f1 | rev) #reverse cut leaves last part of repo name which is role name

if [ -z "$DEPLOY_CREDENTIALS" ]; then
    curl -u $DEPLOY_CREDENTIALS $1/?$role
else
    curl $1/?$role
fi