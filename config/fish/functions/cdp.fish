function cdp
    set -l project (ls-project | fzf -1 -q "$argv")
    if not test -z $project
        cd "$HOME/projects/$project"
    end
end
