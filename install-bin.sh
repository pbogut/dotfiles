#!/bin/bash
#=================================================
# name:   __get.sh
# author: Pawel Bogut <http://pbogut.me>
# date:   19/12/2017
#=================================================
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # dotfiles directory
cd bin
get() {
  echo -n "Downloading $2 from $1 ..."
  if hash curl 2>&- ; then
      curl -s -L "$1" -o "$2"
  elif hash wget 2>&- ; then
      wget -q --no-check-certificate -O "$1" "$2"
  else
     echo "error! You need to have curl or wget installed."
     exit 1
   fi
   chmod +x $2
   echo "done"
}

get 'https://raw.githubusercontent.com/colinmollenhour/modman/master/modman' modman
get 'https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar' phpcs
get 'https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar' phpcbf
get 'http://static.phpmd.org/php/latest/phpmd.phar' phpmd
get 'http://getcomposer.org/composer.phar' composer
get 'https://files.magerun.net/n98-magerun.phar' n98-magerun

cd ..
