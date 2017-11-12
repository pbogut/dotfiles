#!/bin/bash
#=================================================
# name:   .profile
# author: Pawel Bogut <http://pbogut.me>
# date:   11/11/2017
#=================================================
export PATH="$HOME/projects/github.com/elixir-lang/elixir/bin:$PATH"
export PATH="$HOME/.scripts:$PATH"
export PATH="$HOME/.bin:$PATH"

[ -f ~/.profile.local ] && source ~/.profile.local
