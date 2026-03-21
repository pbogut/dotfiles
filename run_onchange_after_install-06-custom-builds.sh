#!/usr/bin/env bash
#=================================================
# name:   run_onchange_after_install-06-custom-builds.sh
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   21/03/2026
#=================================================
build_path="$HOME/.local/cache/custom-builds"
mkdir -p "$build_path"

# Install swaybg with namespace support
if [[ ! -d "$build_path/swaybg" ]]; then
    cd "$build_path" || exit 1
    git clone https://github.com/pbogut/swaybg.git -b layer-set-namespace
    cd swaybg || exit 1
else
    cd ~/.local/cache/custom-builds/swaybg || exit 1
    git pull --rebase
fi
if [[ ! -d build ]]; then
    meson setup build
fi

ninja -C build
cp -f "$build_path/swaybg/build/swaybg" "$HOME/.local/bin/swaybg"
