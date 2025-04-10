#!/usr/bin/env bash
#=================================================
# name:   run_once_after_install-rust
# author: pbogut <pbogut@pbogut.me>
# date:   06/03/2024
#=================================================
# {{- if .install_rustup }} [[[ Install rustup
rustup target add wasm32-unknown-unknown
rustup toolchain install nightly
rustup toolchain install stable
rustup component add rust-analyzer --toolchain nightly
rustup component add rust-analyzer --toolchain stable
rustup component add rust-src --toolchain nightly
rustup component add rust-src --toolchain stable
rustup component add rustfmt --toolchain nightly
rustup component add rustfmt --toolchain stable
# {{ else }}
RUSTC_WRAPPER=""
# Install rustup ]]] {{- end }}

cargo install --git https://github.com/pbogut/enrichmail.git
cargo install --git https://github.com/pbogut/cargo-workspace.git
cargo install --git https://github.com/pbogut/rbw.git --branch add-uris-to-list

cargo install \
    mprocs \
    rtx-cli \
    bacon
