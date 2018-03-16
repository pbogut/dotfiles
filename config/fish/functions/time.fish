function time
    /usr/bin/time -f "\nreal\t%Es\nuser\t%Us\nsys\t%S" $argv
end
