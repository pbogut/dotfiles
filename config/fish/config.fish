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
    set -q MOPIDY_PORT
    or set -l MOPIDY_PORT 6600
    screen -U -D -RR ncmpcpp ncmpcpp -p $MOPIDY_PORT $argv
end

# abbreviations
abbr gst git status
abbr dc docker-compose

# load profile if not already loaded
# source $HOME/.profile
set -l temp_path
for i in (seq (count $PATH))
    if test -n $PATH[$i]
        and not contains $PATH[$i] $temp_path
        set temp_path $temp_path $PATH[$i]
    end
end
set -xg PATH $temp_path
set -e temp_path
