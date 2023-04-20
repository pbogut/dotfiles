#echo "Checking for system updates..."
# sudo pacman -Syu
sudo pacman -Sy

# if no paru installed then build it with cargo
if ! paru --version; then
  echo "Installing paru dependencies ..."
  sudo pacman -S rustup
  echo "Installing paru ..."
  cargo install paru
  paru -S paru && cargo uninstall paru
fi

echo "Installing packages..."
paru -S \
  apg \
  atool \
  base-devel \
  bluez-hcitool \
  cmake \
  copyq \
  dunst \
  enca \
  go \
  gtk3-print-backends \
  i3wm i3lock \
  imagemagick \
  inetutils \
  inotify-tools \
  jq \
  kmonad-bin \
  lldb \
  maim slop \
  mopidy mpc \
  ncmpcpp \
  neomutt \
  neovim \
  network-manager-applet \
  nm-applet \
  nodejs npm \
  notmuch-runtime notmuch \
  noto-fonts-emoji \
  numlockx \
  pandoc \
  paru \
  picom \
  playerctl \
  polybar \
  pulsemixer \
  python python-pip \
  python-black \
  python-isort \
  qutebrowser \
  ranger \
  redshift \
  rescuetime \
  ripgrep \
  rofi \
  ruby \
  rustup \
  shfmt \
  starship \
  texlive-most \
  tmux \
  udevil \
  udisksvm \
  ueberzug \
  unclutter \
  w3m \
  wget \
  which \
  wmctrl \
  xcwd-git \
  xdotool \
  xob \
  xrandr \
  xtitle \
  yarn \
  yt-dlp \
  zenity

if [[ $(hostname) == 'silverspoon' ]]; then
  paru -S \
    intel-media-driver
fi

pip install \
  guessit \
  i3-py \
  i3ipc \
  neovim-remote \
  pynvim \
  steamctl \
  trakt.py \
  upnpclient \
  vim-vint \
  visidata \
  --upgrade

gem install \
  clipboard \
  mail \
  nokogiri \
  redcarpet \
  rotp

go install github.com/nsf/gocode@latest
go install github.com/pbogut/exail@latest
go install github.com/pbogut/mails-go-web@latest
go install golang.org/x/tools/gopls@latest

rustup toolchain install nightly
rustup toolchain install stable
rustup component add rust-analyzer --toolchain nightly
rustup component add rust-analyzer --toolchain stable
rustup component add rust-src --toolchain nightly
rustup component add rust-src --toolchain stable
rustup component add rustfmt --toolchain nightly
rustup component add rustfmt --toolchain stable

cargo install stylua

yarn global add \
  @mozilla/readability \
  elm \
  html-beautify \
  jsdom \
  qutejs \
  readability-cli \
  -y

gitpac all

# git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.3.0
# source ~/.asdf/asdf.sh
# source ~/.asdf/completions/asdf.bash
# asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
# asdf plugin-add php https://github.com/odarriba/asdf-php.git
# asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git

# Imports Node.js release team's OpenPGP keys to main keyring
# bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
