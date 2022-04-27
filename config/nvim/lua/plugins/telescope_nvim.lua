local u = require('utils')
local actions = require('telescope.actions')
local actions_layout = require('telescope.actions.layout')
local builtin = require('telescope.builtin')
local telescope = require('telescope')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local action_state = require('telescope.actions.state')
local conf = require('telescope.config').values

u.map('n', '<space>fr', function()
  builtin.live_grep()
end)
u.map('n', '<space>fR', function()
  builtin.live_grep({
    search_dirs = {
      vim.fn.getcwd() .. '/vendor',
    },
  })
end)
u.map('n', '<space>ft', function()
  builtin.filetypes()
end)
u.map('n', '<space>fa', function()
  builtin.find_files()
end)
u.map('n', '<space>ff', function()
  builtin.find_files({
    no_ignore = true,
  })
end)
u.map('n', '<space>fF', function()
  builtin.find_files({
    no_ignore = true,
    hidden = true,
  })
end)
u.map('n', '<space>fd', function()
  pickers.new({
    prompt_title = 'Database',
    finder = finders.new_table({
      results = vim.fn['db#url_complete']('g:'),
      -- entry_maker = ''
    }),
    sorter = conf.generic_sorter({}),
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
  }):find()
end)
u.map('n', '<space>fb', function()
  builtin.buffers()
end)
u.map('n', '<space>fm', function()
  builtin.oldfiles({ only_cwd = true })
end)
u.map('n', '<space>fM', function()
  builtin.oldfiles()
end)
u.map('n', '<space>et', function()
  builtin.find_files({
    cwd = os.getenv('DOTFILES') .. '/config/nvim/templates',
  })
end)
u.map('n', '<space>es', function()
  builtin.find_files({ cwd = os.getenv('DOTFILES') .. '/config/nvim/snippets' })
end)
u.map('n', '<space>ec', function()
  builtin.find_files({ cwd = os.getenv('DOTFILES') })
end)
u.map('n', '<space>en', function()
  builtin.find_files({ cwd = os.getenv('DOTFILES') .. '/config/nvim' })
end)
u.map('n', '<space>ep', function()
  builtin.find_files({ cwd = vim.fn.stdpath('data') .. '/site/pack/packer/' })
end)
u.map('n', '<space>fg', function()
  builtin.git_status()
end)
u.map('n', '<space>gf', function()
  local file = u.string_under_coursor()
  file = file:gsub('[~%.\\/]', ' ')
  builtin.grep_string({ search = u.trim_string(file) })
end)
u.map('n', '<space>gF', function()
  local file = u.string_under_coursor()
  file = file:gsub('[~%.\\/]', ' ')
  builtin.grep_string({ search = u.trim_string(file) })
end)
u.map('n', '<space>gw', function()
  builtin.grep_string()
end)
u.map('n', '<space>gr', ':Rg<cr>')

local last_query = ''
u.command('Rg', function(bang, query)
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
  builtin.grep_string({ search = query, use_regex = bang, search_dirs = dirs })
end, { nargs = '?', qargs = true, bang = true, complete = 'dir' })

telescope.setup({
  defaults = {
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
          vim.cmd('Trouble quickfix')
        end,
        ['<m-q>'] = function(id)
          actions.send_to_qflist(id)
          vim.cmd('Trouble quickfix')
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
  },
})
require('telescope').load_extension('fzf')
