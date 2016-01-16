#!/bin/zsh
# Plugin list
plugins="rails n98-magerun"

mydir=${0:a:h}
# Load all files from .shell/zshrc.d directory
for plugin in $plugins; do
  if [ -d $mydir/../oh-my-zsh/plugins/$plugin ]; then
    for pluginfile in $mydir/../oh-my-zsh/plugins/$plugin/*.zsh; do
      source $pluginfile
    done
  fi
done
