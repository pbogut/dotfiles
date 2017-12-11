function mpc
    if string match -rq "\-p" "($argv)"
        /usr/bin/mpc $argv
    else
        set -q MOPIDY_PORT
        or set -l MOPIDY_PORT 6600
        /usr/bin/mpc -p $MOPIDY_PORT $argv
    end
end
