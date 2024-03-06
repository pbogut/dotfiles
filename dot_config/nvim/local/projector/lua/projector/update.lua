local M = {}

function M.errors(lines, opts)
  local errors = {}

  if opts.after and not opts.insert then
    errors[#errors+1] = '`after` requires `insert` key'
  end
  if opts.insert and not opts.after then
    errors[#errors+1] = '`insert` requires `after` key'
  end
  if opts.replace and not opts.with then
    errors[#errors+1] = '`replace` requires `with` key'
  end
  if opts.with and not opts.replace then
    errors[#errors+1] = '`with` requires `replace` key'
  end

  if opts.insert then
    local same = false
    for line_no, line in pairs(lines) do
      if line:match(opts.after) then
        if lines[line_no+1] == opts.insert[1] then
          same = true
          for new_line_no, new_line in pairs(opts.insert) do
            same = same or lines[line_no + new_line_no] == new_line
          end
        end
        if same == true then
          errors[#errors+1] = 'value is already inserted'
          break
        end
      end
    end
    -- errors = merge(errors, M.errors_after(lines, opts))
  end

  if opts.replace then
    if type(opts.with) ~= 'table' then
      local pattern = opts.with:gsub('%%([^%%%d%w])', '%1'):gsub('([^%%%w%s])', '%%%1'):gsub('%%%d', '(.-)')
      for _, line in pairs(lines) do
        -- dump({line:match(pattern), pattern, line})
        if line:match(pattern) then
          errors[#errors+1] = 'line already replaced'
        end
      end
    end
  end

  if opts.prepend then
    local same = false
    for line_no, _ in pairs(lines) do
      if lines[line_no] == opts.prepend[1] then
        same = true
        for new_line_no, new_line in pairs(opts.prepend) do
          same = same or lines[line_no + new_line_no - 1] == new_line
        end
      end
      if same == true then
        errors[#errors+1] = 'value is already inserted'
        break
      end
    end
  end

  if opts.append then
    local same = false
    for line_no, _ in pairs(lines) do
      if lines[line_no] == opts.append[1] then
        same = true
        for new_line_no, new_line in pairs(opts.append) do
          same = same or lines[line_no + new_line_no - 1] == new_line
        end
      end
      if same == true then
        errors[#errors+1] = 'value is already inserted'
        break
      end
    end
  end

  return errors
end

function M.update(lines, opts)
  if opts.after then
    -- print('use insert / after function')
    lines = M.insert(lines, opts)
  end

  if opts.replace then
    -- print('use replace function')
    lines = M.replace(lines, opts)
  end

  if opts.prepend then
    -- print('use prepend function')
    lines = M.prepend(lines, opts)
  end

  if opts.append then
    -- print('use append function')
    lines = M.append(lines, opts)
  end

  return lines

  -- print('use update function')
  -- return opts.update(lines)
end

function M.insert(lines, opts)
  local new_lines = {}
  for _, line in pairs(lines) do
    new_lines[#new_lines + 1] = line
    if line:match(opts.after) then
      for _, new_line in pairs(opts.insert) do
        new_lines[#new_lines+1] = new_line
      end
    end
  end
  return new_lines
end

function M.prepend(lines, opts)
  local new_lines = {}
  for _, new_line in pairs(opts.prepend) do
      new_lines[#new_lines+1] = new_line
  end
  for _, line in pairs(lines) do
    new_lines[#new_lines+1] = line
  end
  return new_lines
end

function M.append(lines, opts)
  local new_lines = {}
  for _, line in pairs(lines) do
    new_lines[#new_lines+1] = line
  end
  for _, new_line in pairs(opts.append) do
      new_lines[#new_lines+1] = new_line
  end
  return new_lines
end

function M.replace(lines, opts)
  local new_lines = {}
  local with = opts.with
  if type(with) == 'table' then
    with = table.concat(opts.with, "\n")
  end
  for _, line in pairs(lines) do
    if line:match(opts.replace) then
      local replacement = line:gsub(opts.replace, with)
      local parts = vim.fn.split(replacement, '\n')
      for _, new_line in pairs(parts) do
        new_lines[#new_lines+1] = new_line
      end
    else
      new_lines[#new_lines+1] = line
    end
  end
  return new_lines
end

return M
