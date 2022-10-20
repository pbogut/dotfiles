local command = vim.api.nvim_create_user_command
local u = require('utils')
local k = vim.keymap
local actions = require('telescope.actions')
local make_entry = require('telescope.make_entry')
local actions_layout = require('telescope.actions.layout')
local builtin = require('telescope.builtin')
local telescope = require('telescope')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local action_state = require('telescope.actions.state')
local conf = require('telescope.config').values

k.set('n', '<space>fp', require('telescope').extensions['tmux-projects'].ls_projects)
k.set('n', '<space>fr', function()
  builtin.live_grep()
end)
k.set('n', '<space>fR', function()
  builtin.live_grep({
    search_dirs = {
      vim.fn.getcwd() .. '/vendor',
    },
  })
end)
k.set('n', '<space>st', function()
  builtin.filetypes()
end)
k.set('n', '<space>fa', function()
  builtin.find_files()
end)
k.set('n', '<space>ff', function()
  builtin.find_files({
    no_ignore = true,
  })
end)
k.set('n', '<space>fF', function()
  builtin.find_files({
    no_ignore = true,
    hidden = true,
  })
end)
k.set('n', '<space>fm', function()
  vim.fn['fzf_mru#mrufiles#refresh']()
  vim.cmd.Telescope('fzf_mru', 'current_path')
end)
k.set('n', '<space>fd', function()
  require('plugins.vim_dadbod').load_connections()
  pickers
    .new({
      prompt_title = 'Database',
      finder = finders.new_table({
        results = vim.fn['db#url_complete']('g:') or {},
        -- entry_maker = ''
      }),
      sorter = conf.file_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          if selection == nil then
            print('[telescope] Nothing currently selected')
            return
          end
          actions.close(prompt_bufnr)
          vim.b.db = vim.api.nvim_eval(selection[1])
          vim.b.db_selected = selection[1]
          vim.schedule(function()
            vim.fn['db#adapter#ssh#create_tunnel'](vim.b.db)
          end)
        end)
        return true
      end,
    })
    :find()
end)
k.set('n', '<space>fM', function()
  local result = {}
  local files = vim.fn['bm#all_files']()
  for _, file in ipairs(files) do
    local line_nrs = vim.fn['bm#all_lines'](file)
    for _, line_nr in ipairs(line_nrs) do
      local bookmark = vim.fn['bm#get_bookmark_by_line'](file, line_nr)
      local content = ''
      if bookmark.annotation:len() > 0 then
        content = 'Annotation: ' .. bookmark.annotation
      elseif bookmark.content:len() > 0 then
        content = bookmark.content
      else
        content = 'empty line'
      end
      result[#result + 1] = file .. ':' .. line_nr .. ':0:' .. content
    end
  end

  pickers
    .new({
      prompt_title = 'BookMarks',

      finder = finders.new_table({
        results = result,
        entry_maker = make_entry.gen_from_vimgrep({}),
      }),
      previewer = conf.grep_previewer({}),
      sorter = conf.generic_sorter({}),
    })
    :find()
end)
k.set('n', '<space>fb', function()
  builtin.buffers()
end)
k.set('n', '<space>fo', function()
  builtin.oldfiles({ only_cwd = true })
end)
k.set('n', '<space>fO', function()
  builtin.oldfiles()
end)
k.set('n', '<space>ft', function()
  builtin.find_files({
    cwd = os.getenv('DOTFILES') .. '/config/nvim/templates',
  })
end)
k.set('n', '<space>fs', function()
  builtin.find_files({ cwd = os.getenv('DOTFILES') .. '/config/nvim/snippets' })
end)
k.set('n', '<space>fc', function()
  builtin.find_files({ cwd = os.getenv('DOTFILES') })
end)
k.set('n', '<space>fn', function()
  builtin.find_files({ cwd = os.getenv('DOTFILES') .. '/config/nvim' })
end)
k.set('n', '<space>fP', function()
  builtin.find_files({ cwd = vim.fn.stdpath('data') .. '/site/pack/packer/' })
end)
k.set('n', '<space>fg', function()
  builtin.git_status()
end)
k.set('n', '<space>gf', function()
  local file = u.string_under_coursor()
  file = file:gsub('[~%.\\/]', ' ')
  builtin.grep_string({ search = u.trim_string(file) })
end)
k.set('n', '<space>gF', function()
  local file = u.string_under_coursor()
  file = file:gsub('[~%.\\/]', ' ')
  builtin.grep_string({ search = u.trim_string(file) })
end)
k.set('n', '<space>gw', function()
  builtin.grep_string()
end)
k.set('n', '<space>gr', '<cmd>Rg<cr>')

local last_query = ''
command('Rg', function(opt)
  local query = opt.args
  if query == '' then
    query = last_query
  else
    last_query = query
  end
  local dirs = { vim.fn.getcwd() }
  if query:match('%/$') then
    local dir = query:gsub('(.-) ([^%s]+%/)$', '%2')
    if dir:byte(1) ~= 47 then
      local sep = '/./'
      if dir:byte(1) == 46 then
        sep = '/'
      end
      dir = vim.fn.getcwd() .. sep .. query:gsub('(.-) ([^%s]+%/)$', '%2')
    end
    dirs = { dir }
    query = query:gsub('(.-) ([^%s]+%/)$', '%1')
  end
  local message = '"' .. query .. '"'
  local short_dirs = {}
  for _, dir in pairs(dirs) do
    if dir ~= vim.fn.getcwd() then
      short_dirs[#short_dirs + 1] = dir:gsub('^.*%.%/', '')
    end
  end
  if #short_dirs > 0 then
    message = message .. ' in ' .. table.concat(short_dirs, ', ')
  end
  print(message)
  builtin.grep_string({ search = query, use_regex = opt.bang, search_dirs = dirs })
end, { nargs = '?', bang = true, complete = 'dir' })

telescope.setup({
  defaults = {
    -- path_display = {
    --   shorten = { len = 3, exclude = { 1, 2, -1, -2, -3 } },
    -- },
    path_display = function(opts, path)
      local cwd = vim.fn.getcwd()
      local result = path
      if path:sub(1, #cwd) == cwd then
        result = '.' .. path:sub(#cwd + 1)
      end
      local parts = vim.split(result, '/')

      for i, part in pairs(parts) do
        if i ~= 1 and i ~= 2 and i ~= #parts and i ~= #parts - 1 and i ~= #parts - 2 then
          if part:len() > 6 then
            parts[i] = part:sub(1, 3) .. '…' .. part:sub(part:len() - 1)
          end
        end
      end

      return table.concat(parts, '/')
    end,
    -- sorting_strategy = "ascending",
    -- layout_strategy = 'vertical',
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
    },
    mappings = {
      i = {
        ['<c-j>'] = actions.move_selection_next,
        ['<c-k>'] = actions.move_selection_previous,
        ['<c-s>'] = actions_layout.toggle_preview,

        ['<esc>'] = actions.close,

        ['<cr>'] = actions.select_default,
        ['<c-x>'] = actions.select_horizontal,
        ['<c-v>'] = actions.select_vertical,
        ['<c-t>'] = actions.select_tab,

        ['<c-u>'] = actions.preview_scrolling_up,
        ['<c-d>'] = actions.preview_scrolling_down,

        ['<PageUp>'] = actions.results_scrolling_up,
        ['<PageDown>'] = actions.results_scrolling_down,

        ['<tab>'] = actions.toggle_selection + actions.move_selection_worse,
        ['<s-tab>'] = actions.toggle_selection + actions.move_selection_better,
        ['<c-q>'] = function(id)
          actions.send_selected_to_qflist(id)
          vim.cmd.Trouble('quickfix')
        end,
        ['<m-q>'] = function(id)
          actions.send_to_qflist(id)
          vim.cmd.Trouble('quickfix')
        end,
        ['<c-l>'] = actions.complete_tag,
        ['<c-_>'] = actions.which_key, -- keys from pressing <C-/>
      },
      n = {}, -- not a fan, hence <esc> above
    },
  },
  extensions = {
    fzf = {
      fuzzy = true, -- false will only do exact matching
      override_generic_sorter = true, -- override the generic sorter
      override_file_sorter = true, -- override the file sorter
      case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
      -- the default case_mode is "smart_case"
    },
    ['ui-select'] = {
      require('telescope.themes').get_dropdown({
        -- even more opts
      }),
    },
  },
})
require('telescope').load_extension('fzf')
require('telescope').load_extension('ui-select')
require('telescope').load_extension('git_worktree')
require('telescope').load_extension('tmux-git-worktree')
require('telescope').load_extension('tmux-projects')
require('telescope').load_extension('fzf_mru')
