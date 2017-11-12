function dotenv
    set -l command
    set -l environment
    set -l file

    getopts $argv | while read -l key value
        switch $key
            case _
                set command $value
            case x
                set options '-xg'
                set command $value
            case e
                set environment $value
            case f
                set file $value
        end
    end

    test -n "$file"
    or set file (string replace -r '\.$' '' ".env.$environment")
    test -n "$options"
    or set -l options '-x'

    for i in (cat $file | grep -v '^#' | grep '^[A-Z_]*\=\|export [A-Z_]*\=')
        set -l var (string replace --regex '(export )?(.*)=(.*)' '$2' $i)
        set -l val (string replace --regex '(export )?(.*)=(.*)' '$3' $i)
        if test -n "$var"
            and test -n "$val"
            set $options $var $val
        end
    end

    if test -n "$command"
        eval $command
    end
end
