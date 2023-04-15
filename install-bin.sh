#!/bin/bash
#=================================================
# name:   __get.sh
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   19/12/2017
#=================================================
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # dotfiles directory
cd bin || exit
get() {
  echo -n "Downloading $1 from $2 ..."
  if hash curl 2>&-; then
    if curl -s -L "$2" -o "$1.tmp"; then
      mv "$1.tmp" "$1"
    else
      rm "$1.tmp"
    fi
  elif hash wget 2>&-; then
    if wget -q --no-check-certificate -O "$2" "$1.tmp"; then
      mv "$1.tmp" "$1"
    else
      rm "$1.tmp"
    fi
  else
    echo "error! You need to have curl or wget installed."
    exit 1
  fi
  chmod +x "$1"
  echo "done"
}

get composer 'http://getcomposer.org/composer.phar'
get dep 'https://deployer.org/deployer.phar'
get modman 'https://raw.githubusercontent.com/colinmollenhour/modman/master/modman'
get n98-magerun 'https://files.magerun.net/n98-magerun.phar'
get phpcpd 'https://phar.phpunit.de/phpcpd.phar'
get robo 'http://robo.li/robo.phar'

go get -u -v github.com/go-shiori/go-readability/cmd/...

psylocal="$HOME/.local/share/psysh/"
mkdir -p "$psylocal"
cd "$psylocal" || exit 3
wget 'http://psysh.org/manual/en/php_manual.sqlite'
cd - || exit 3

psylink=$(
  curl -s 'https://github.com/bobthecow/psysh/releases' |
    grep compat.tar.gz |
    head -n1 |
    sed 's,.*href="\(.*\)" rel=".*,\1,'
)

temp=$(mktemp -d)
wget "https://github.com$psylink" -O "$temp/psysh.tar.gz"
cd "$temp" || exit 3
tar xvf psysh.tar.gz
mv "$temp/psysh" "$dir/bin/"
chmod +x "$dir/bin/psysh"
cd - || exit 3

cd ..
