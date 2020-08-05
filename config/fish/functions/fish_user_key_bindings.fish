function fish_user_key_bindings
    bind -M insert \ej down-or-search
    bind -M insert \ek up-or-search
    bind -M insert \cp history-search-backward
    bind -M insert \cn history-search-forward
end

fzf_key_bindings
