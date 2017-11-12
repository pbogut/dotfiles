function cdr
    set -q argv[1]
    and set -l dir $argv[1]
    or set -l dir (pwd)
    set -l root_expr '^.git$\|^composer.json$'
    set -l is_root (ls -a $dir | grep "$root_expr")
    set -l cont $2

    if test "$is_root" != ""
        and test "$cont" != "y"
        read -p "set_color green; echo 'This is project root, wish to continue anyway (y/n)? '" -n1 cont
        set_color normal
    else
        set cont y
    end

    if test "$cont" = "y"
        set dir (dirname $dir)
        set is_root (ls -a $dir | grep "$root_expr")

        if test "$dir" != "/"
            if test "$is_root" = ""
                cdr "$dir" y
            end
        else
            set_color red
            echo "Could not find project root"
        end

        if test "$is_root" != ""
            cd "$dir"
        end
    end
end
