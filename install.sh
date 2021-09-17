#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

########## Variables

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # dotfiles directory
echo -n "Updating submodules ..."
git submodule sync && git submodule update --init
echo "done"
olddir=~/.dotfiles_backup/$(date +%s%N) # old dotfiles backup directory
read -d '' files <<"EOF"
    ackrc
    aliases
    bin
    ctags
    emacs.d/init.el
    gitconfig
    githelpers
    gitignore
    inputrc
    jshintrc
    npmrc
    offlineimap-hooks
    offlineimap.py
    profile
    screenrc
    scripts
    terminfo
    urlview
    vimrc
    yaourtrc
    zshrc
    zshenv
    zprofile
    zshrc.d
    bashrc
    bash_profile
    Xdefaults
    composer/composer.json
    config/autostart/autostart.desktop
    config/dircolors-solarized
    config/dunst/dunstrc
    config/feh/keys
    config/fish
    config/gtk-3.0/settings.ini
    config/i3/config
    config/i3/i3status.conf
    config/i3/workspaces
    config/ncmpcpp/config
    config/ncmpcpp/bindings
    config/nvim/init.lua
    config/nvim/lua
    config/nvim/ginit.vim
    config/nvim/config
    config/nvim/templates
    config/nvim/snippets
    config/pip/pip.conf
    config/polybar
    config/qutebrowser/config.py
    config/qutebrowser/keys.conf
    config/qutebrowser/qutebrowser.conf
    config/qutebrowser/js
    config/ranger/devicons.py
    config/ranger/plugins/devicons_linemode.py
    config/ranger/rc.conf
    config/ranger/rifle.conf
    config/rofi/config.rasi
    config/roxterm.sourceforge.net
    config/Franz/Plugins/todoist
    gtk-2.0
    i3blocks.conf
    local/share/applications/ranger.desktop
    local/share/applications/browser.desktop
    local/share/applications/email.desktop
    local/share/applications/freetube.desktop
    mutt/mailcap
    mutt/muttrc
    mutt/solarized-dark-16.muttrc
    scspell/dictionary.txt
    vim/autoload/plug.vim
    vim/ftplugin
    vim/mysnippets
    vim/mytemplates
    vim/plugin
    weechat/alias.conf
    weechat/cron.txt
    weechat/weechat.conf
EOF
read -d '' directories <<"EOF"
    .gocode
    .vim/backupfiles
    .vim/swapfiles
    .vim/undofiles
EOF
##########

# create dotfiles_old in homedir
echo -n "Creating $olddir for backup of any existing dotfiles in ~ ..."
mkdir -p $olddir
echo "done"

# change to the dotfiles directory
echo -n "Changing to the $dir directory ..."
cd $dir
echo "done"

# create required directories
echo "Creating missing directories"
for directory in $directories; do
  if [ ! -e ~/$directory ]; then
    echo -en "\t~/$directory "
    mkdir -p ~/$directory
    echo "done"
  fi
done
# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks from the homedir to any files in the ~/dotfiles directory specified in $files
echo "Backing up current files to $olddir/"
for file in $files; do
  if [ -e ~/.$file ]; then
    echo -en "\t~/.$file "
    mv ~/.$file $olddir/
    echo "done"
  fi
done
echo "Creating symlinks in home directory"
for file in $files; do
  echo -en "\t~/.$file "
  # crate directory if not exists
  mkdir -p $(dirname $HOME/.$file)
  ln -sf $dir/$file $HOME/.$file
  echo "done"
done

echo "Post install actions"

echo -en "\tMaking scripts executable ... "
find $dir -name "*.sh" -exec chmod +x {} \; >/dev/null 2>&1
find $dir -name "*.zsh" -exec chmod +x {} \; >/dev/null 2>&1
find $dir -name "*.phar" -exec chmod +x {} \; >/dev/null 2>&1
chmod +x ~/.scripts/* >/dev/null 2>&1
chmod +x ~/.offlineimap-hooks/* >/dev/null 2>&1
echo "done"

echo -en "\tSet ranger as default manager (xdg-mime) ... "
[[ -n $(command -v xdg-mime) ]] && xdg-mime default ranger.desktop 'inode/directory'
echo "done"

echo -en "\tSet browser script as default browser (xdg-settings) ... "
[[ -n $(command -v xdg-mime) ]] && xdg-settings set default-web-browser browser.desktop
echo "done"

echo -en "\tSet email script as default emial (xdg-settings) ... "
[[ -n $(command -v xdg-mime) ]] && xdg-settings set default-url-scheme-handler mailto email.desktop
echo "done"

echo -en "\tSet email script as default mailto handler (xdg-mime) ... "
[[ -n $(command -v xdg-mime) ]] && xdg-mime default email.desktop 'x-scheme-handler/mailto'
echo "done"

echo -en "\tSet freetube as default youtube handler (xdg-mime) ... "
[[ -n $(command -v xdg-mime) ]] && xdg-mime default freetube.desktop 'x-scheme-handler/freetube'
echo "done"

echo -en "\t"$(
  if [[ -n $(command -v gio) ]]; then
    gio mime inode/directory ranger.desktop
  elif [[ -n $(command -v gvfs-mime) ]]; then
    gvfs-mime --set inode/directory ranger.desktop
  fi
) && echo " ... done"

# echo -en "\tInstall vim/neovim plugins ... "
# [[ -n $(command -v /bin/vim) ]] && /bin/vim -u ./vim/silent.vimrc +PlugInstall +qa
# [[ -n $(command -v /bin/nvim) ]] && /bin/nvim -u ./vim/silent.vimrc +PlugInstall +qa
# echo "done"

echo -e "\nChange your shell if you wish:\n"
which fish >/dev/null && echo -e "\tchsh $(id -un) -s $(which fish)"
which zsh >/dev/null && echo -e "\tchsh $(id -un) -s $(which zsh)"

read -p "Do you want to update bin folder? [yN]" -n 1 -s ask
echo ""
[[ $ask == "y" ]] && ./install-bin.sh
