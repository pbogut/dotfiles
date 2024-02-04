#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # dotfiles directory
links_only=false

usage() {
  echo "Ussage: ${0##*/} [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -l, --links-only     only create symlinks and exit"
  echo "  -h, --help           display this help and exit"
}

while test $# -gt 0; do
  case "$1" in
    --links-only|-l)
      links_only=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

# fix scripts executable attribute
find "$dir" -iname '*.sh' -exec chmod +x {} \;
find "$dir" -iname '*.zsh' -exec chmod +x {} \;

echo -n "Updating submodules ..."

git submodule sync
git submodule update --init config/dircolors-solarized
git submodule update --init zshrc.d/plugins/zsh-autosuggestions

echo "done"
olddir=~/.dotfiles_backup/$(date +%s%N) # old dotfiles backup directory
read -r -d '' files <<"EOF"
    Xdefaults
    Xresources
    ackrc
    aliases
    asoundrc
    autostart.redeye.sh
    autostart.silverspoon.sh
    bash_profile
    bashrc
    bin
    composer/composer.json
    config/Franz/Plugins/todoist
    config/MangoHud
    config/alacritty
    config/autostart/autostart.desktop
    config/bacon
    config/chrome-flags.conf
    config/chromium-flags.conf
    config/clang-format
    config/conky
    config/dircolors-solarized
    config/dircolors.256dark
    config/dunst/dunstrc
    config/environment.d
    config/feh/keys
    config/fish
    config/foot/foot.ini
    config/gamemode.ini
    config/gtk-3.0/settings.ini
    config/gtk-3.0/gtk.css
    config/gtk-4.0/settings.ini
    config/gtk-4.0/gtk.css
    config/i3/config
    config/i3/i3status.conf
    config/i3/workspaces
    config/kmonad
    config/lazygit/config-zellij.yml
    config/lazygit/config-nvim.yml
    config/lazygit/config.yml
    config/lf/cleaner
    config/lf/lfrc
    config/lf/preview
    config/mpv/input.conf
    config/mpv/mpv.conf
    config/mpv/script-settings/mpvDLNA.conf
    config/mpv/scripts/lazy_open.lua
    config/mpv/scripts/minidlna-subs.lua
    config/mpv/scripts/send-to-phone.lua
    config/mpv/scripts/slice.lua
    config/mpv/scripts/trakt
    config/ncmpcpp/bindings
    config/ncmpcpp/config
    config/networkmanager-dmenu/config.ini
    config/nvim/after
    config/nvim/colors
    config/nvim/filetype.lua
    config/nvim/ginit.vim
    config/nvim/init.lua
    config/nvim/lazy-lock.json
    config/nvim/local
    config/nvim/lua
    config/nvim/snippets
    config/nvim/templates
    config/paru/paru.conf
    config/picom/picom.conf
    config/pip/pip.conf
    config/polybar
    config/qutebrowser/config.py
    config/qutebrowser/js
    config/qutebrowser/keys.conf
    config/qutebrowser/qutebrowser.conf
    config/qutebrowser/userscripts
    config/okularpartrc
    config/okularrc
    config/ranger/commands.py
    config/ranger/devicons.py
    config/ranger/plugins/devicons_linemode.py
    config/ranger/rc.conf
    config/ranger/rifle.conf
    config/rofi/config.rasi
    config/roxterm.sourceforge.net
    config/starship.toml
    config/sway/config
    config/sway/locktile.png
    config/systemd/user/kmonad.service
    config/systemd/user/swayidle.service
    config/systemd/user/syncthing.service
    config/tmux
    config/waybar
    config/wezterm/wezterm.lua
    config/wob
    config/wofi
    config/xob
    config/zellij
    ctags
    emacs.d/init.el
    gitconfig
    githelpers
    gitignore
    gitpac.json
    grouppack.json
    gtk-2.0
    i3blocks.conf
    icons/polar
    inputrc
    jshintrc
    local/share/applications/browser.desktop
    local/share/applications/email.desktop
    local/share/applications/freetube.desktop
    local/share/applications/ranger.desktop
    mutt/mailcap
    mutt/muttrc
    mutt/solarized-dark-16.muttrc
    mutt/solarized-dark-256.muttrc
    npmrc
    offlineimap-hooks
    offlineimap.py
    profile
    profile.redeye
    profile.silverspoon
    screenrc
    scripts
    scspell/dictionary.txt
    terminfo
    urlview
    vim/autoload/plug.vim
    vim/ftplugin
    vim/plugin
    vimrc
    weechat/alias.conf
    weechat/cron.txt
    weechat/weechat.conf
    yaourtrc
    zprofile
    zshenv
    zshrc
    zshrc.d
EOF

read -r -d '' directories <<"EOF"
    .gocode
    .vim/backupfiles
    .vim/swapfiles
    .vim/undofiles
EOF

# create dotfiles_old in homedir
echo -n "Creating $olddir for backup of any existing dotfiles in ~ ..."
mkdir -p "$olddir"
echo "done"

# change to the dotfiles directory
echo -n "Changing to the $dir directory ..."
cd "$dir" || exit 3
echo "done"

# create required directories
echo "Creating missing directories"
for directory in $directories; do
  if [ ! -e "$HOME/$directory" ]; then
    echo -en "\t~/$directory "
    mkdir -p "$HOME/$directory"
    echo "done"
  fi
done
# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks from the homedir to any files in the ~/dotfiles directory specified in $files
echo "Backing up current files to $olddir/"
for file in $files; do
  if [ -e "$HOME/.$file" ]; then
    echo -en "\t~/.$file "
    mv "$HOME/.$file" "$olddir/"
    echo "done"
  fi
done
echo "Creating symlinks in home directory"
for file in $files; do
  echo -en "\t~/.$file "
  # crate directory if not exists
  mkdir -p "$(dirname "$HOME/.$file")"
  ln -sf "$dir/$file" "$HOME/.$file"
  echo "done"
done

mkdir -p "$HOME/.gpg-config"
touch "$HOME/.profile.local"
touch "$HOME/.profile.$(hostname)"

# qutebrowser profiles {{{
mkidr -p "$HOME/.config/qutebrowser/media"
mkidr -p "$HOME/.config/qutebrowser/qbwork"

if [[ ! -d "$HOME/.config/qutebrowser/media/config/userscripts" ]]; then
  ln -s "config/qutebrowser/userscripts" "$HOME/.config/qutebrowser/media/config/userscripts"
fi
if [[ ! -d "$HOME/.config/qutebrowser/qbwork/config/userscripts" ]]; then
  ln -s "config/qutebrowser/userscripts" "$HOME/.config/qutebrowser/qbwork/config/userscripts"
fi
# qutebrowser profiles }}}

if $links_only; then
  exit 0
fi

echo "Post install actions"

echo -en "\tMaking scripts executable ... "
find "$dir" -name "*.sh" -exec chmod +x {} \; >/dev/null 2>&1
find "$dir" -name "*.zsh" -exec chmod +x {} \; >/dev/null 2>&1
find "$dir" -name "*.phar" -exec chmod +x {} \; >/dev/null 2>&1
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

echo -en "\t$(
  if [[ -n "$(command -v gio)" ]]; then
    gio mime inode/directory ranger.desktop
  elif [[ -n $(command -v gvfs-mime) ]]; then
    gvfs-mime --set inode/directory ranger.desktop
  fi
)" && echo " ... done"

echo -e "\nChange your shell if you wish:\n"
test -f /usr/bin/fish && echo -e "\tchsh $(id -un) -s $(which fish)"
test -f /usr/bin/zsh && echo -e "\tchsh $(id -un) -s $(which zsh)"

read -r -p "Do you want to update bin folder? [yN]" -n 1 -s ask
echo ""
if [[ $ask == "y" ]]; then
  ./install-bin.sh
fi
