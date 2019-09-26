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
    curl -s -L "$2" -o "$1.tmp" && mv "$1.tmp" "$1" || rm "$1.tmp"
  elif hash wget 2>&-; then
    wget -q --no-check-certificate -O "$2" "$1.tmp" && mv "$1.tmp" "$1" || rm "$1.tmp"
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
get dep 'https://deployer.org/deployer.phar'

psylocal="$HOME/.local/share/psysh/"
mkdir -p $psylocal && cd $psylocal && wget 'http://psysh.org/manual/en/php_manual.sqlite' && cd -

psylink=$(curl -s 'https://github.com/bobthecow/psysh/releases' |
    grep compat.tar.gz |
    head -n1 |
    sed 's,.*href="\(.*\)" rel=".*,\1,'
)

temp=$(mktemp -d)
wget "https://github.com$psylink" -O $temp/psysh.tar.gz
cd $temp
tar xvf psysh.tar.gz
mv $temp/psysh $dir/bin/
chmod +x $dir/bin/psysh
cd -

cd ..
