;; extends
(
 command
  name: (command_name) @_cmd (#eq? @_cmd "psql")
  argument: (word) @_arg (#eq? @_arg "-c")
  argument: (raw_string) @sql (#offset! @sql 0 1 0 -1)
)
