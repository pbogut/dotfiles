function fish_mode_prompt_custom -d "Custom indicator"
    set_color brblack
    set_color -ob (__fish_mode_prompt_color)
    switch $fish_bind_mode
        case insert
            echo -n " I"
        case default
            echo -n " N"
        case replace_one
            echo -n " R"
        case visual
            echo -n " V"
    end
    set_color normal
    set_color (__fish_mode_prompt_color)
    echo " "
end

function __fish_mode_prompt_color
    switch $fish_bind_mode
        case insert
            echo yellow
        case default
            echo brblue
        case replace_one
            echo red
        case visual
            echo magenta
    end
end
