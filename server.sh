#!/bin/bash

# SETUP
# git clone -n --depth 1 https://github.com/wilmardo/ansible-travisci-deployserver.git .
# git checkout HEAD server.sh

lansible_path=/opt/deploy/LANsible/
roles_path=/opt/deploy/roles/
playbook_paths=($lansible_path/plays/*.yml)
log_path=/opt/deploy/deployserver/

log_error() {
    printf "%(%F %T)T Error : $1 \n" -1 >> $log_path/deploy-error.log
}
log_deploy() {
    printf "%(%F %T)T Successful command: '$1' \n" -1 >> $log_path/deploy.log
}

errorcheck() {
    typeset cmd="$*"
    typeset ret_code

    echo cmd=$cmd
    eval $cmd
    ret_code=$?
    if [ $ret_code != 0 ]; then
        log_error "['$ret_code'] when executing command: '$cmd'"
        exit $ret_code
    else
         log_deploy $cmd
    fi
}

pull_repository() {
    typeset path="$roles_path/wilmardo.$1"
    if [ -d $path ]; then
        cd $path
        command="git pull"
    else
        cd $roles_path
        command="git clone --depth 1 https://github.com/wilmardo/ansible-role-$1.git wilmardo.$1"
    fi
    errorcheck $command
}

pull_lansible() {
    if [ -d $lansible_path ]; then
        cd $lansible_path
        command="git pull"
    else
        command="git clone --depth 1 https://github.com/wilmardo/LANsible.git $lansible_path"
    fi
    errorcheck $command
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
	   *)
            if $p == "lansible"; then
                pull_lansible
            else
                log_error "Received unrecognized message: '$p'"
            fi
       ;;
	esac
done
