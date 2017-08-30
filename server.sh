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
galaxy_roles_path=/opt/deploy/roles/
log_path=/opt/deploy/deployserver/

log_error() {
    printf "%(%F %T)T Error : $1 \n Trace:\n $2" -1 >> $log_path/deploy-error.log
}
log_deploy() {
    printf "%(%F %T)T Successful command: $1 \n" -1 >> $log_path/deploy.log
}

# https://stackoverflow.com/questions/8211844/get-exit-code-for-command-in-bash-ksh
safeCommand() {
    typeset cmd="$*"
    typeset ret_code

    cmd_output=$(eval $cmd 2>&1)
    ret_code=$?
    if [ $ret_code != 0 ]; then
        log_error "['$ret_code'] when executing command: '$cmd'" "$cmd_output"
    else
         log_deploy "$cmd"
    fi
}

pull_role() {
    typeset path="$roles_path/wilmardo.$1"

    if [ -d $path ]; then
        safeCommand "git --git-dir=$path/.git pull"
    else
        safeCommand "git clone --depth 1 https://github.com/wilmardo/ansible-role-$1.git $roles_path/wilmardo.$1"
    fi
}

pull_galaxy_roles() {
    safeCommand "ansible-galaxy install --roles-path $galaxy_roles_path -r $lansible_path/requirements.yml"
}

update_all_hosts() {
    for playbook in "${playbook_paths[@]}"; do
        safeCommand "ansible-playbook $playbook $1"
    done
}

update_lansible() {
    changed_files=$1

    for change in "${changed_files[@]}"; do
        changed_dir=$( echo "$change" | cut -d '/' -f 1)
        case "$changed_dir" in
        "plays")
            changed_sub_dir=$( echo "$change" | cut -d '/' -f 2)
            case "$changed_sub_dir" in
            "host_vars")
            #TODO: Fix this, find which playbook to run
                safeCommand "ansible-playbook $lansible_path/$change --limit ("$(basename "$change" .yml)")"
            ;;
            "group_vars")
                if [ $( echo "$change" | cut -d '/' -f 3) == "all.yml" ]; then
                    update_all_hosts
                else
                    safeCommand "ansible-playbook $lansible_path/$change"
                fi
            ;;
            *.yml)
                safeCommand "ansible-playbook $lansible_path/$change"
            ;;
            esac
        ;;
        "files")
            update_all_hosts "--tags 'ssh-keys'"
        ;;
        "requirements.yml")
            pull_galaxy_roles
        ;;
        esac
    done
}

pull_lansible() {
    if [ ! -d $lansible_path ]; then
        safeCommand "git clone --depth 1 git@github.com:wilmardo/LANsible.git $lansible_path"
    else
        safeCommand "git --git-dir=$lansible_path/.git --work-tree=$lansible_path fetch"
        safeCommand "git --git-dir=$lansible_path/.git --work-tree=$lansible_path diff --name-only @{upstream}"
        update_lansible "$cmd_output"
        safeCommand "git --git-dir=$lansible_path/.git --work-tree=$lansible_path pull"
    fi
}

deploy_role() {
    IFS='|' read -r -a in_use_playbooks <<< ${playbook_roles[$1]}
    for playbook in "${in_use_playbooks[@]}"; do
        safeCommand "cd $lansible_path"
        safeCommand "ansible-playbook $lansible_path/plays/$playbook.yml"
    done
}

# SETUP
# Pull main project and pull roles
if [ ! -d $lansible_path ]; then
  pull_lansible
  pull_galaxy_roles
fi

# DYNAMIC VARIABLES
# playbook_paths: Path to playbooks in LANsible
# playook_roles: Associative array, the keys are the role names, the value contains the playbooks where the role is used
# play_name: Playbook name without extension
playbook_paths=($lansible_path/plays/*.yml)
declare -A playbook_roles=()

for path in "${playbook_paths[@]}"; do
    play_name=("$(basename "$path" .yml)")
    roles=( $(grep "role: wilmardo." $path | grep -v '^#' | cut -d '.' -f 2) )

    for role in "${roles[@]}"; do
        playbook_roles[$role]+="$play_name|"
    done
done

for role in "${!playbook_roles[@]}"; do
    pull_role $role
done


# MAIN LOOP
ncat -lk 56789 | while IFS=, read -r -a p
do
    case "${!playbook_roles[@]}" in
    *"$p"*)
        pull_role $p
        deploy_role $p
    ;;
    *)
        if [ "$p" == "lansible" ]; then
            pull_lansible
        else
            log_error "Received unrecognized message: '$p'"
        fi
    ;;
    esac
done
