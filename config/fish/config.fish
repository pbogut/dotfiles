fish_vi_key_bindings

# disable greeting
set fish_greeting

# aliases
alias q exit
alias so source
alias o i3-open

alias vim nvim
alias m ncmpcpp

function ncmpcpp
  set -l LC_ALL en_GB.utf8
  set -q MOPIDY_PORT; or set -l MOPIDY_PORT 6600
  screen -U -D -RR ncmpcpp ncmpcpp -p $MOPIDY_PORT $argv
end

# fzf configuration
set -gx FZF_DEFAULT_OPTS "
  --filepath-word --reverse
  --bind=ctrl-e:preview-down,ctrl-y:preview-up,ctrl-s:toggle-preview
  --bind=ctrl-w:backward-kill-word
  --height 40%
  --cycle
  "
