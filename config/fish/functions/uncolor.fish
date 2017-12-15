function uncolor
  echo $argv | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" | sed "s,\x1B(B,,g"
end
