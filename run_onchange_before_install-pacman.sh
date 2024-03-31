#!/usr/bin/env bash
#=================================================
# name:   run_once_before_install-packages
# author: pbogut <pbogut@pbogut.me>
# date:   06/03/2024
#=================================================
echo "> Update pacman database..."
echo "# pacman -Sy"
sudo pacman -Sy

export CARGO_NET_GIT_FETCH_WITH_CLI=true

# if no paru installed then build it with cargo
if ! paru --version; then
    echo "> Installing paru dependencies ..."
    echo "# sudo pacman -S rustup gcc cmake pkgconf fakeroot git"
    sudo pacman -S rustup gcc cmake pkgconf fakeroot git
    echo "> Installing paru ..."
    rustup toolchain install stable
    cargo install paru
    "$HOME/.cargo/bin/paru" -S paru && cargo uninstall paru
fi

echo "> Installing packages..."
paru -S \
    --skipreview \
    --needed \
    adwaita-dark \
    age \
    alacritty-sixel-git \
    apg \
    atool \
    base-devel \
    bluez-hcitool \
    chafa \
    cmake \
    copyq \
    dbus-broker \
    dunst \
    enca \
    fakeroot \
    gcc \
    git \
    glow \
    gnome-keyring \
    go \
    grim \
    gtk3-print-backends \
    imagemagick \
    inetutils \
    inotify-tools \
    jq \
    kmonad-bin \
    libpipewire \
    libwireplumber \
    lldb \
    maim slop \
    mpv mpv-mpris \
    neomutt \
    neovim-git \
    network-manager-applet \
    nodejs npm \
    notmuch-runtime notmuch \
    noto-fonts-emoji \
    numlockx \
    pandoc \
    paru \
    pipewire \
    pkgconf \
    playerctl \
    polybar \
    pulsemixer \
    python python-pip \
    python-black \
    python-isort \
    qutebrowser \
    ranger \
    redshift \
    ripgrep \
    rofi \
    ruby \
    rustup \
    shfmt \
    slurp \
    starship \
    sway \
    swayidle \
    tmux \
    udevil \
    udisksvm \
    unclutter \
    w3m \
    waybar \
    wezterm \
    wget \
    which \
    wireplumber \
    wl-clipboard \
    wmctrl \
    wob \
    wofi \
    wtype \
    xcwd-git \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-kde \
    xdg-desktop-portal-wlr \
    xdotool \
    xob \
    xtitle \
    yarn \
    yt-dlp-git \
    zenity

if [[ $(hostname) == 'silverspoon' ]]; then
    paru -S \
        --skipreview \
        --needed \
        intel-media-driver
fi
