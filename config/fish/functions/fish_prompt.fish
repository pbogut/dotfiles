function fish_prompt
    set -l last_status $status
    set_color --bold red
    echo -n "["
    set_color normal
    set_color brblue
    echo -n (id -un)
    set_color --bold red
    echo -n "@"
    set_color normal
    set_color brblue
    if test -n "$SSH_CLIENT"
        or test -n "$SSH_TTY"
        set_color yellow
    end
    echo -n (hostname)
    set_color --bold red
    echo -n "] ("
    set_color normal
    set_color brblue
    echo -n (prompt_pwd)
    set_color --bold red
    echo -n ")"
    set -l git_branch (string replace --regex -a "[\(\)]" "" (__fish_git_prompt))
    if test -n $git_branch
        set_color normal
        set_color blue
        echo -n " "$git_branch
    end
    if test $last_status -ne 0
        set_color red
    else
        set_color green
    end
    echo -n " ["(date +'%H:%M:%S %Y-%m-%d')"]"
    if test $last_status -ne 0
        echo -n " [ ERROR: $last_status ]"
    end

    echo
    echo -n (fish_mode_prompt_custom)
    set_color --bold red
    if test (id -un) = 'root'
        echo '# '
    else
        echo 'λ '
    end
end
