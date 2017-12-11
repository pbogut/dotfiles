function sc
    bash -c (cat ~/.commands | fzf | sed 's,[^;]*;;; ,,')
end
