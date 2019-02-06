#!/bin/bash
_deployer_get_command_list() {
	dep --no-ansi | sed "1,/Available commands/d" | awk '/^ +[a-z]+/ { print $1 }'
}

_deployer () {
    compadd `_deployer_get_command_list`
}

compdef _deployer dep
