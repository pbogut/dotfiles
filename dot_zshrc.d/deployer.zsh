# Deployer basic command completion
_deployer_get_command_list() {
  dep --no-ansi | sed "1,/Available commands/d" | awk '/^ +[a-z]+/ { print $1 }'
}

_deployer_get_hosts() {
  cat deploy.php | grep '^host' | sed 's/host..\(.*\)../\1/g'
}

_deployer() {
  local state
  _arguments '1: :->arg1' '2: :->arg2'

  case $state in
    arg1)
      compadd $(_deployer_get_command_list)
      ;;
    arg2)
      if [[ ${words[2]} =~ "deploy" ]]; then
        compadd $(_deployer_get_hosts)
      else
        compadd $(_deployer_get_command_list)
      fi
      ;;
  esac
}

compdef _deployer dep
