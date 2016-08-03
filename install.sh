#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

########## Variables

dir=~/dotfiles                    # dotfiles directory
olddir=~/dotfiles_`date +%s%N`    # old dotfiles backup directory
read -d '' files <<"EOF"
    inputrc
    offlineimap-hooks
    offlineimap.py
    screenrc
    vimrc
    zshrc
    zlogin
    zshrc.d
    tmux
    tmux.conf
    yaourtrc
    ackrc
    scripts
    bin
    gitconfig
    githelpers
    terminfo
    weechat/cron.txt
    weechat/alias.conf
    weechat/weechat.conf
    config/nvim/init.vim
    config/roxterm.sourceforge.net
    config/autostart/autostart.desktop
    config/autostart/rescuetime.desktop
    config/i3/config
    config/i3/i3status.conf
    config/ranger/rc.conf
    config/ranger/devicons.py
    config/ranger/plugins/devicons_linemode.py
    config/ncmpcpp/config
    config/dircolors-solarized
    vim/bundle/Vundle.vim
    vim/autoload/plug.vim
    composer/composer.json
    mutt/muttrc
    mutt/mailcap
    mutt/solarized-dark-16.muttrc
    urlview
EOF
read -d '' directories <<"EOF"
    .vim/undofiles
    .vim/swapfiles
    .vim/backupfiles
    .vim/bundle
    .vim/autoload
    .config/nvim
    .config/i3
    .config/ranger
    .config/ranger/plugins
    .config/autostart
    .config/ncmpcpp
    .weechat
    .composer
    .mutt
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
for directory in $directories; do
    echo -n "Creating directory ~/$directory ..."
    mkdir -p ~/$directory
    echo "done"
done
# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks from the homedir to any files in the ~/dotfiles directory specified in $files
for file in $files; do
    echo -n "Moving ~/.$file to $olddir/ ..."
    mv ~/.$file $olddir/
    echo "done"
    echo -n "Creating symlink to $file in home directory ..."
    ln -s $dir/$file ~/.$file
    echo "done"
done

find $dir -name "*.sh" -exec chmod +x {} \;
find $dir -name "*.zsh" -exec chmod +x {} \;
find $dir -name "*.phar" -exec chmod +x {} \;

install_zsh () {
    # Test to see if zshell is installed.  If it is:
    if [ -f /bin/zsh -o -f /usr/bin/zsh ]; then
        # Set the default shell to zsh if it isn't currently set to zsh
        if [[ ! $(echo $SHELL) == *"/zsh" ]]; then
            chsh -s $(which zsh)
        fi
    else
        # If zsh isn't installed, get the platform of the current machine
        platform=$(uname);
        # If the platform is Linux, try an apt-get to install zsh and then recurse
        if [[ $platform == 'Linux' ]]; then
            if [[ -f /etc/redhat-release ]]; then
                sudo yum install zsh
                install_zsh
            fi
            if [[ -f /etc/debian_version ]]; then
                sudo apt-get install zsh
                install_zsh
            fi
            if [[ -f /etc/arch-release ]]; then
                sudo pacman -S zsh
            fi
            # If the platform is OS X, tell the user to install zsh :)
        elif [[ $platform == 'Darwin' ]]; then
            echo "Please install zsh, then re-run this script!"
            exit
        fi
    fi
}

install_zsh

echo ""
echo "Additional setup"
echo ""
echo "nvm:"
echo "  curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash"
echo "rvm:"
echo "  curl -sSL https://get.rvm.io | bash"
echo ""

