#!/bin/bash
#=================================================
# name:   __get.sh
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   19/12/2017
#=================================================
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # dotfiles directory
cd bin
get() {
  echo -n "Downloading $1 from $2 ..."
  if hash curl 2>&-; then
    curl -s -L "$2" -o "$1"
  elif hash wget 2>&-; then
    wget -q --no-check-certificate -O "$2" "$1"
  else
    echo "error! You need to have curl or wget installed."
    exit 1
  fi
  chmod +x $1
  echo "done"
}

get composer 'http://getcomposer.org/composer.phar'
get modman 'https://raw.githubusercontent.com/colinmollenhour/modman/master/modman'
get n98-magerun 'https://files.magerun.net/n98-magerun.phar'
get phpcbf 'https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar'
get phpcs 'https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar'
get phpmd 'http://static.phpmd.org/php/latest/phpmd.phar'
get robo 'http://robo.li/robo.phar'

cd ..
