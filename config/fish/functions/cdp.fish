function cdp
    set -l project (ls-project | fzf -1 -q "$argv" --preview "cd $HOME/Projects/{};git status | head -n2; echo "\n"; git -c color.status=always status -s")
    if not test -z $project
        cd "$HOME/Projects/$project"
    end
end
