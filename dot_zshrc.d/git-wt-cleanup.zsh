git-wt-cleanup() {
  if [[ $1 == --help || $1 == -h ]]; then
    command git-wt-cleanup "$@"
    return
  fi

  local worktree_dir=$PWD
  local git_common_dir rc
  git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
    command git-wt-cleanup "$@" -- "$worktree_dir"
    return
  }

  cd "$git_common_dir" || return 1
  command git-wt-cleanup "$@" -- "$worktree_dir"
  rc=$?

  if [[ $rc -ne 0 && -d $worktree_dir ]]; then
    cd "$worktree_dir" || return $rc
  fi
  return $rc
}
