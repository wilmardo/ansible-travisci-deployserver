#!/bin/bash

# SETUP
# git clone -n --depth 1 https://github.com/wilmardo/ansible-travisci-deployserver.git .
# git checkout HEAD server.sh


lansible_path=(/root/LANsible/)
playbook_paths=($lansible_path/plays/*.yml)

errorcheck() {
    typeset cmnd="$*"
    typeset ret_code

    echo cmnd=$cmnd
    eval $cmnd
    ret_code=$?
    if [ $ret_code != 0 ]; then
        printf "%(%F %T)T Error : ['$ret_code'] when executing command: '$cmnd' \n" -1 >> deploy-error.log
        exit $ret_code
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
            command="ansible-playbook $lansible_path/plays/$p.yml"
		    errorcheck $command
	   ;; 
	esac
done
