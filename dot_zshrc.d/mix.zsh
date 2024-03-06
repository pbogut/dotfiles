#!/bin/bash
#=================================================
# name:   mix.zsh
# author: Pawel Bogut <pbogut@pbogut.me>
# date:   27/06/2017
#=================================================
#
_mix_command_list () {
  mix help | awk '{ print $2 }'
}

_mix () {
  compadd `_mix_command_list`
}

compdef _mix mix
