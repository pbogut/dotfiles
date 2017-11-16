function cdp
    set -l project (ls-project | fzf -1 -q "$argv")
    if test -n $project
        cd "$HOME/projects/$project"
    end
end
