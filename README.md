Deployserver TravisCI-Ansible [![Build Status](https://travis-ci.org/wilmardo/ansible-travisci-deployserver.svg?branch=master)](https://travis-ci.org/wilmardo/ansible-travisci-deployserver)
=========

Deployserver for TravisCI tested Ansible roles. To be further developed, see the comments in server.sh for more clarification.

Example .travis.yml deploy
----------------
    deploy:
      - provider: script
        script: /deploy/client.sh "http://example.com"
        on:
          branch: master


License
-------

BSD

Author Information
------------------

Wilmar den Ouden

https://wilmardenouden.nl