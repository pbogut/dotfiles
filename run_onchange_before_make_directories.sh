#!/usr/bin/env bash
#=================================================
# name:   run_onchange_before_make_directories
# author: author <author_contact>
# date:   07/04/2024
#=================================================
mkdir -p "{{ .home }}/Desktop"
mkdir -p "{{ .home }}/Documents"
mkdir -p "{{ .home }}/Downloads"
mkdir -p "{{ .home }}/Music"
mkdir -p "{{ .home }}/Pictures"
mkdir -p "{{ .home }}/Share"
mkdir -p "{{ .home }}/Templates"
mkdir -p "{{ .home }}/Videos"
