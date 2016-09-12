# Laravel5 basic command completion
_modman_get_command_list () {
  # modman --help | sed "1,/---/d" | grep -v '  modman\|^-\|^\<\|^$\|^    ' | sed 's/\[//g' | sed 's/\]//g' | awk '/^ +[-a-z]+/ { print $1  }'
  modman --help | sed "1,/---/d" | awk '/^ +[a-z]+/ { print $1  }'
}

_modman_get_flag_list () {
}

_modman () {
  if [ -d .modman ]; then
    compadd `_modman_get_command_list`
  else
    compadd "init"
  fi
}

compdef _modman modman
