#!/bin/bash

# SETUP
# git clone -n --depth 1 https://github.com/wilmardo/ansible-travisci-deployserver.git .
# git checkout HEAD server.sh

lansible_path=/opt/deploy/LANsible/
roles_path=/opt/deploy/roles/
playbook_paths=($lansible_path/plays/*.yml)
log_path=/opt/deploy/deployserver/

errorcheck() {
    typeset cmd="$*"
    typeset ret_code

    echo cmd=$cmd
    eval $cmd
    ret_code=$?
    if [ $ret_code != 0 ]; then
        printf "%(%F %T)T Error : ['$ret_code'] when executing command: '$cmd' \n" -1 >> $log_path/deploy-error.log
        exit $ret_code
    else
         printf "%(%F %T)T Successful command: '$cmd' \n" -1 >> deploy.log
    fi
}

pull_repository() {
    typeset cmd="cd $roles_path/ansible-role-$1"
    if $cmd; then
        cd $roles_path/ansible-role-$1 && git pull
    else
        cd $roles_path && git clone --depth 1 https://github.com/wilmardo/ansible-role-$1.git wilmardo.$1
    fi
}

playbooks=()
for path in "${playbook_paths[@]}"
do
	playbooks+=("$(basename "$path" .yml)")
done

ncat -lk 56789 | while IFS=, read -r -a p
do
	case "${playbooks[@]}" in  
	   *"$p"*)
	        pull_repository $p
            command="ansible-playbook $lansible_path/plays/$p.yml"
		    errorcheck $command
	   ;; 
	esac
done
