# gpg-config basic command completion

_gpg-config () {
    if (( CURRENT == 2 )); then
      compadd "list"
      compadd "get"
      compadd "set"
  elif (( CURRENT == 3 )); then
      compadd $(gpg-config list)
  fi
}

compdef _gpg-config gpg-config
