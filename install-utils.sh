#echo "Checking for system updates..."
# sudo pacman -Syu
sudo pacman -Sy
# $ curl https://nixos.org/nix/install | sh
#

install_yay() {
    if [[ "$(which yay)" == "yay not found" ]]; then
        wget https://storage.pbogut.me/yay-9.4.2-1-x86_64.pkg.tar.xz
        sudo pacman -U yay-9.4.2-1-x86_64.pkg.tar.xz
        rm -fr yay-9.4.2-1-x86_64.pkg.tar.xz
    fi
}

echo "Installing yay..."
sudo pacman -S wget which
install_yay
echo "Installing neovim..."
yay -S \
    abook \
    net-utils \
    picom \
    dmenu \
    go \
    gtk3-print-backends \
    i3wm i3lock i3blocks \
    imagemagick \
    inotify-tools \
    maim slop \
    mopidy mpc \
    ncmpcpp \
    neomutt \
    neovim \
    neovim-qt \
    network-manager-applet \
    nm-applet \
    nodejs npm \
    notmuch-runtime notmuch \
    numlockx \
    pandoc \
    pulsemixer \
    python python-pip python2 python2-pip \
    qutebrowser \
    ranger \
    redshift \
    rescuetime \
    rofi \
    shfmt \
    texlive-most \
    udevil \
    udisksvm \
    xcape \
    xrandr \
    xtitle \
    dunst \
    --noconfirm -needed

pip install \
    i3-py \
    i3ipc \
    flake8 \
    pynvim \
    neovim-remote \
    vim-vint \
    visidata \
    --upgrade

pip2 install \
    pynvim \
    --upgrade

gem install redcarpet
gem pristine --all

go get github.com/nsf/gocode
go get github.com/pbogut/mails-go-web
go get github.com/pbogut/exail

[[ $(command -v yarn) ]] || npm install -g yarn
yarn global add \
    elm \
    eslint \
    html-beautify \
    jshint \
    -y

# git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.3.0
# source ~/.asdf/asdf.sh
# source ~/.asdf/completions/asdf.bash
# asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
# asdf plugin-add php https://github.com/odarriba/asdf-php.git
# asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git

# Imports Node.js release team's OpenPGP keys to main keyring
# bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
