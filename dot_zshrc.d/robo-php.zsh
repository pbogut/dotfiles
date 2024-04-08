# Laravel5 basic command completion
_robo_get_command_list () {
  robo --no-ansi 2>/dev/null| sed "1,/Available commands/d" | awk '/^ +[a-z]+/ { print $1 }'
}

_robo () {
  compadd `_robo_get_command_list`
}

compdef _robo robo
