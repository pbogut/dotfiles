# Magento2 command completion
_mage_get_command_list() {
  if [[ -f ./bin/magento ]]; then
    ./bin/magento --no-ansi | sed "1,/Available commands/d" | awk '/^ +[a-z]+/ { print $1 }'
  fi
}

_mage_docker_get_command_list() {
  if [[ -f ./mage-docker ]]; then
    ./mage-docker --no-ansi | sed "1,/Available commands/d" | awk '/^ +[a-z]+/ { print $1 }'
  fi
}

_mage() {
  compadd $(_mage_get_command_list)
}

_mage_docker() {
  compadd $(output-cache -g -l 60 -k $PWD || _mage_docker_get_command_list | output-cache -s -k $PWD)
}

compdef _mage magento
compdef _mage_docker mage-docker
