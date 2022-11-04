;; extends
((name) @todo
 (#eq? @todo "FIXME"))

((name) @debug
 (#eq? @debug "DEBUG"))

((name) @todo
 (#eq? @todo "TODO"))

((tag_name) @todo
 (#eq? @todo "@todo"))

((tag_name) @debug
 (#eq? @debug "@debug"))

((tag_name) @todo
 (#eq? @todo "@fixme"))
