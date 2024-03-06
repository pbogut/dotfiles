#!/usr/bin/env bash
#=================================================
# name:   run_after_install-gem
# author: pbogut <pbogut@pbogut.me>
# date:   05/03/2024
#=================================================
self_hash="$(sha1sum "${BASH_SOURCE[0]}" | awk '{print $1}')"
gem_hash_file="gem_hash_${self_hash}_$(gem environment user_gemhome | sha1sum | awk '{print $1}')"

# install only once per ruby version or this file change
if [ -f "$HOME/.cache/chezmoi/$gem_hash_file" ]; then
    exit 0
fi

mkdir -p "$HOME/.cache/chezmoi/"

gem install \
    clipboard \
    english \
    erb \
    json \
    mail \
    nokogiri \
    redcarpet \
    rotp \
    yaml

touch "$HOME/.cache/chezmoi/$gem_hash_file"
