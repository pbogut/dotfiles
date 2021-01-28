#!/bin/bash
#=================================================
# name:   input-nerd-font.sh
# author: Pawel Bogut <https://pbogut.me>
# date:   18/12/2020
#=================================================
tmpdir=$(mktemp -d)
cd $tmpdir
if [[ ! -f $HOME/.cache/Input_Fonts.zip ]]; then
  curl 'https://input.fontbureau.com/build/?fontSelection=whole&a=0&g=0&i=serifs_round&l=serifs_round&zero=0&asterisk=0&braces=0&preset=default&line-height=1.2&accept=I+do&email=' -o $HOME/.cache/Input_Fonts.zip
fi
echo $tmpdir
cp $HOME/.cache/Input_Fonts.zip ./
unzip Input_Fonts.zip

# get / update nerd fonts
git cl ryanoasis/nerd-fonts || cd $HOME/Projects/github.com/ryanoasis/nerd-fonts && git pull
cd $tmpdir

find Input_Fonts/ -iname '*.ttf' | while read font; do
  options="--mono --complete --careful"
  $HOME/Projects/github.com/ryanoasis/nerd-fonts/font-patcher $options "$font" -out ~/.fonts/
  options="--complete --careful"
  $HOME/Projects/github.com/ryanoasis/nerd-fonts/font-patcher $options "$font" -out ~/.fonts/
done

fc-cache -f
