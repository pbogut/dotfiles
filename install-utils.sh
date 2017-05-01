#echo "Checking for system updates..."
# sudo pacman -Syu
sudo pacman -Sy
# $ curl https://nixos.org/nix/install | sh
#

install_pacaur() {
    # Create a tmp-working-dir an navigate into it
    mkdir -p /tmp/pacaur_install
    cd /tmp/pacaur_install

    # If you didn't install the "base-devil" group,
    # we'll need those.
    sudo pacman -S binutils make gcc fakeroot --noconfirm --needed

    # Install pacaur dependencies from arch repos
    sudo pacman -S expac yajl git --noconfirm -needed

    # Install "cower" from AUR
    curl -o PKGBUILD https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=cower
    makepkg PKGBUILD --skippgpcheck
    sudo pacman -U cower*.tar.xz --noconfirm -needed

    # Install "pacaur" from AUR
    curl -o PKGBUILD https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=pacaur
    makepkg PKGBUILD
    sudo pacman -U pacaur*.tar.xz --noconfirm -needed

    # Clean up...
    cd ~
    rm -r /tmp/pacaur_install
}


echo "Installing pacaur..."
install_pacaur
echo "Installing neovim..."
pacaur -S \
    abook \
    anamnesis \
    cava \
    compton \
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
    neovim-git \
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
    texlive-most \
    twmn-git \
    udevil \
    udisksvm \
    xcape \
    xrandr \
    xtitle \
    --noconfirm -needed

pip install \
    i3-py \
    i3ipc \
    khal \
    neovim \
    neovim-remote \
    --upgrade

pip2 install \
    neovim \
    --upgrade

gem install redcarpet
gem pristine --all

go get github.com/nsf/gocode
go get github.com/pbogut/mails-go-web

[[ $(command -v yarn) ]] || npm install -g yarn
yarn global add \
    elm \
    eslint \
    html-beautify \
    jshint \
    -y

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.3.0
source ~/.asdf/asdf.sh
source ~/.asdf/completions/asdf.bash
asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin-add php https://github.com/odarriba/asdf-php.git
asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git

# Imports Node.js release team's OpenPGP keys to main keyring
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring

