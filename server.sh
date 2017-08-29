#!/bin/bash

# SETUP
# git clone -n --depth 1 https://github.com/wilmardo/ansible-travisci-deployserver.git .
# git checkout HEAD server.sh

# STATIC VARIABLES
# lansible_path: Path to LANsible repository
# roles_path: Path to save the roles to
# log_path: Path to save logfiles to
lansible_path=/opt/deploy/LANsible/
roles_path=/opt/deploy/roles/
log_path=/opt/deploy/deployserver/

# DYNAMIC VARIABLES
# playbook_paths: Path to playbooks in LANsible
# play_name: Playbook name without extension
# playbooks: Array with playbook names, without extension
#
playbook_paths=($lansible_path/plays/*.yml)
playbooks=()
for path in "${playbook_paths[@]}"; do
	play_name=("$(basename "$path" .yml)")
	playbooks+=$play_name
    deps=( $(grep "role: wilmardo." $path | cut -d '.' -f 2) )

    for dep in "${deps[@]}"; do
        array_name=roles_using_${dep//-/_}
        if [ -v ${!array_name} ]; then
            echo testIf
            declare -a $array_name=$play_name
        else
            echo testElse
            declare $array_name+=$play_name
        fi
    done
done

testsetup=setup
varname="roles_using_$testsetup"
echo ${!varname[0]}

for test in "declare ${!varname[@]}"; do
    echo $test
done

for play in "${playbooks[@]}"; do
    varname=deps_$play
    echo ${!varname}
done

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
        command="cd $path && git pull"
    else
        command="cd $roles_path && git clone --depth 1 https://github.com/wilmardo/ansible-role-$1.git wilmardo.$1"
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

ncat -lk 56789 | while IFS=, read -r -a p
do
	case "${playbooks[@]}" in  
	   *"$p"*)
	        pull_repository $p
		    errorcheck "ansible-playbook $lansible_path/plays/$p.yml"
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
