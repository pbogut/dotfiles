local command = vim.api.nvim_create_user_command
local popup = require('plenary.popup')
local k = vim.keymap

local args = {}
local default_calendar = nil

local function setup(opts)
  if type(opts.default_calendar) == 'string' and opts.default_calendar:len() > 0 then
    default_calendar = opts.default_calendar
  end
  if type(opts.default_due) == 'string' and opts.default_due:len() > 0 then
    args[#args + 1] = '-d' .. opts.default_due
  end
end

local function get_task(line)
  local task_id = line:match('%[.%]%s+(%d+)')
  local completed = line:match('%[(.)%]%s+')
  if completed == ' ' then
    completed = false
  else
    completed = true
  end
  return {
    id = task_id,
    completed = completed,
  }
end

local function add_task(text)
  local calendar = default_calendar
  local calendar_arg = ''
  if text:match('^%@[a-z]+') or text:match('%@[a-z]+$') then
    calendar = text:gsub('^%@([a-z]+).*', '%1')
    calendar = text:gsub('.*%@([a-z]+)$', '%1')
    text = text:gsub('^%@([a-z]+) ', '')
    text = text:gsub(' %@([a-z]+)$', '')
  end
  if calendar then
    calendar_arg = '-l ' .. vim.fn.shellescape(calendar)
  end
  local cmd = 'todo new ' .. vim.fn.join(args) .. ' ' .. calendar_arg .. ' ' .. vim.fn.shellescape(text)
  local out = vim.fn.system(cmd):gsub('\n', '')
  local task = get_task(out)
  task.line = out
  return task
end

local function close_window(win_id)
  vim.api.nvim_win_close(win_id, true)
end

local function create_window()
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.6)
  local borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' }
  local bufnr = vim.api.nvim_create_buf(false, false)

  local todoman_win_id, win = popup.create(bufnr, {
    title = 'Todo List',
    highlight = 'TodomanWindow',
    line = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    minwidth = width,
    minheight = height,
    borderchars = borderchars,
  })

  vim.api.nvim_win_set_option(win.border.win_id, 'winhl', 'Normal:TodomanBorder')
  vim.api.nvim_create_autocmd('BufModifiedSet', {
    buffer = bufnr,
    callback = function()
      vim.api.nvim_buf_set_option(bufnr, 'modified', false)
    end,
  })
  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = bufnr,
    once = true,
    nested = true,
    callback = function()
      close_window(todoman_win_id)
    end,
  })
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      for i, line in ipairs(lines) do
        local task = get_task(line)
        if not task.id then
          local new_task = add_task(line)
          vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { new_task.line })
        end
      end
    end,
    buffer = bufnr,
  })

  return {
    bufnr = bufnr,
    win_id = todoman_win_id,
  }
end

local function task_file(task_id)
  local file = vim.fn.system('EDITOR=echo todo edit ' .. task_id .. ' --raw'):gsub('\n', '')
  return file
end

local STATUS_COMPLETED = 'completed'
local STATUS_NEEDS_ACTION = 'needs-action'

local function update_status(task_id, status)
  if status == STATUS_COMPLETED then
    vim.fn.system('todo done ' .. task_id)
  elseif status == STATUS_NEEDS_ACTION then
    local file = task_file(task_id)
    vim.fn.system("sed -E 's/^STATUS:COMPLETED/STATUS:NEEDS-ACTION/' -i " .. file)
    vim.fn.system("sed -E '/^PERCENT-COMPLETE:.*/d' -i " .. file)
    vim.fn.system("sed -E '/^COMPLETED:.*/d' -i " .. file)
  end
end

local function delete_task(task_id)
  vim.fn.system('todo delete --yes ' .. task_id)
end

local function open_window(all_tasks)
  all_tasks = all_tasks or false

  local cmd = 'todo list'
  if all_tasks then
    cmd = cmd .. ' -s ANY'
  end
  local out = vim.fn.system(cmd)
  local win_info = create_window()
  local todoman_win_id = win_info.win_id
  local todoman_bufnr = win_info.bufnr

  local contents = vim.split(out:gsub('\n$', ''), '\n')

  vim.api.nvim_win_set_option(todoman_win_id, 'number', true)
  vim.api.nvim_buf_set_name(todoman_bufnr, 'todoman-list')
  vim.api.nvim_buf_set_lines(todoman_bufnr, 0, #contents, false, contents)
  vim.api.nvim_buf_set_option(todoman_bufnr, 'filetype', 'todoman')
  vim.api.nvim_buf_set_option(todoman_bufnr, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(todoman_bufnr, 'bufhidden', 'delete')

  k.set('n', 'dd', function()
    local line = vim.fn.getline('.')
    local task = get_task(line)

    if task.id then
      if vim.fn.confirm('Delete task ' .. task.id .. '?', 'Yes\nNo', 'No') == 1 then
        delete_task(task.id)
        vim.cmd('silent delete')
      end
    else
      vim.cmd.delete()
    end
  end, { buffer = todoman_bufnr })
  k.set('n', '<esc>', function()
    close_window(todoman_win_id)
  end, { buffer = todoman_bufnr })
  k.set('n', 'q', function()
    close_window(todoman_win_id)
  end, { buffer = todoman_bufnr })
  k.set('n', '<cr>', function()
    local line = vim.fn.getline('.')
    local line_nr = vim.fn.line('.')
    local new_line = line
    local task = get_task(line)
    if not task.id then
      return
    end

    if task.completed then
      update_status(task.id, STATUS_NEEDS_ACTION)
      new_line = line:gsub('%[.%]', '[ ]')
    else
      update_status(task.id, STATUS_COMPLETED)
      new_line = line:gsub('%[.%]', '[x]')
    end
    vim.api.nvim_buf_set_lines(todoman_bufnr, line_nr - 1, line_nr, false, { new_line })
  end, { buffer = todoman_bufnr })
end

command('Todo', function(opts)
  local query = opts.args
  if query:len() > 3 then
    local task = add_task(query)
    vim.notify('Task ' .. task.id .. ' created')
  else
    if opts.bang then
      open_window(true)
    else
      open_window()
    end
  end
end, { nargs = '?', bang = true })

return { setup = setup }
