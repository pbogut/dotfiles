function custom_pwd
    set -l start (string sub --length (string length $HOME) (pwd))
    if test $start = $HOME
        string replace "$HOME" "~" (pwd)
    else
        pwd
    end
end
