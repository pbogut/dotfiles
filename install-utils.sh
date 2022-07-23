#echo "Checking for system updates..."
# sudo pacman -Syu
sudo pacman -Sy
# $ curl https://nixos.org/nix/install | sh
#

instal_paru() {
    if [[ "$(which yay)" == "yay not found" ]]; then
        wget http://storage.pbogut.me/paru-1.9.0-1-x86_64.pkg.tar.zst
        sudo pacman -U paru-1.9.0-1-x86_64.pkg.tar.zst
        rm -fr paru-1.9.0-1-x86_64.pkg.tar.zst
    fi
}

echo "Installing paru..."
sudo pacman -S wget which
instal_paru
echo "Installing packages..."
paru -S \
    base-devel \
    cmake \
    atool \
    enca \
    zenity \
    rust \
    xdotool \
    ripgrep \
    bluez-hcitool \
    jq \
    apg
    w3m \
    wmctrl \
    xtitle \
    xcwd-git \
    copyq \
    paru \
    inetutils \
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
    playerctl \
    pulsemixer \
    python python-pip \
    python-black \
    python-isort \
    jedi-language-server \
    flake8 \
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
    yarn \
    yt-dlp \
    yt-dlp-drop-in \
    ruby \
    noto-fonts-emoji \
    dunst

if [[ $hoatname == 'silverspoon' ]]; then
  paru -S \
    intel-media-driver
fi

pip install \
    steamctl \
    upnpclient \
    i3-py \
    i3ipc \
    pynvim \
    neovim-remote \
    vim-vint \
    visidata \
    guessit \
    trakt.py \
    --upgrade

pip2 install \
    pynvim \
    --upgrade

gem install \
  redcarpet \
  nokogiri \
  clipboard \
  mail \
  rotp \
  solargraph
#gem pristine --all

go install github.com/nsf/gocode@latest
go install github.com/pbogut/mails-go-web@latest
go install github.com/pbogut/exail@latest
go install golang.org/x/tools/gopls@latest

cargo install stylua

yarn global add \
    elm \
    eslint \
    html-beautify \
    jshint \
    @tailwindcss/language-server \
    vim-language-server \
    vls \
    bash-language-server \
    pyright \
    dockerfile-language-server-nodejs \
    typescript-language-server \
    @tailwindcss/language-server \
    intelephense \
    vscode-langservers-extracted \
    readability-cli \
    -y

npm install \
  jsdom \
  qutejs \
  @mozilla/readability \
  -g

gitpac all


# git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.3.0
# source ~/.asdf/asdf.sh
# source ~/.asdf/completions/asdf.bash
# asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
# asdf plugin-add php https://github.com/odarriba/asdf-php.git
# asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git

# Imports Node.js release team's OpenPGP keys to main keyring
# bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
