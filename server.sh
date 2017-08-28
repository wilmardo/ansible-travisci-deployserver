#!/bin/sh

lansible_path=(/home/wilmardo/Documents/Development/lansible/)
playbook_paths=($lansible_path/plays/*.yml)

playbooks=()
for path in "${playbook_paths[@]}"
do
	playbooks+=("$(basename "$path" .yml)")
done

ncat -lk 56789 | while IFS=, read -a p
do
	case "${playbooks[@]}" in  
	   *"$p"*) 
		 ansible-playbook $lansible_path/plays/$p.yml
	   ;; 
	esac
done
