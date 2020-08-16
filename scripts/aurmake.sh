#!/bin/bash
#=================================================
# name:   aurmake.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   14/12/2019
#=================================================
# Emergency script with no little dependencies
# used to build yay if not working after system
# upgrade, can be use to build other packages
# as well, but its not very safe as it will 
# blindly execute every PKGBUILD file
#=================================================

package=$1
url="https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"

_pwd=$(pwd)
_dir="$HOME/.cache/aurmake/$package"
mkdir -p "$_dir"
cd $_dir
curl -O "$url"
tar xvf $package.tar.gz
cd $package
makepkg -f
if [[ $? == 0 ]]; then
    package_file=$(ls *.pkg.tar.xz)
    sudo pacman -U $package_file
fi
cd $_pwd
