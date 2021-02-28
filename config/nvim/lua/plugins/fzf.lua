local u = require('utils')
local g = vim.g
local b = vim.b
local fn = vim.fn
local cmd = vim.cmd
local api = vim.api
local f = {}
local l = {}

g.fzf_layout = { down = '~35%' }
g.fzf_command_prefix = "FZF"
-- g.fzf_mru_relative = 1
g.fzf_mru_max = 10000
g.fzf_mru_per_session = 1
g.fzf_action = {
  ['ctrl-t'] = 'tab split',
  ['ctrl-x'] = 'rightbelow split',
  ['ctrl-v'] = 'rightbelow vsplit'
}
g.fzf_preview = "-1 --preview 'sh ~/.scripts/fzf-preview.sh {}'"

u.map('n', '<space>et', ':lua require"plugins.fzf".templates()<CR>')
u.map('n', '<space>es', ':lua require"plugins.fzf".snippets()<CR>')
u.map('n', '<space>ec', ':lua require"plugins.fzf".nvim_config()<cr>')
u.map('n', '<space>ed', ':lua require"plugins.fzf".dotfiles()<cr>')

u.map('n', '<space>fq', ':silent! cclose | lua require"plugins.fzf".quickfix()<cr>')
u.map('n', '<space>fl', ':silent! lclose | lua require"plugins.fzf".loclist()<cr>')

u.map('n', '<space>q', ':silent! cclose | lua require"plugins.fzf".quickfix()<cr>')
u.map('n', '<space>l', ':silent! lclose | lua require"plugins.fzf".loclist()<cr>')

u.map('n', '<space>fa', ':lua require"plugins.fzf".files()<cr>')
u.map('n', '<space>ff', ':lua require"plugins.fzf".all_files()<cr>')
u.map('n', '<space>fF', ':lua require"plugins.fzf".totaly_all_files()<cr>')
u.map('n', '<space>fg', ':lua require"plugins.fzf".git_ls()<cr>')

u.map('n', '<space>gf', ':lua require"plugins.fzf".file_under_coursor()<cr>')
u.map('n', '<space>gF', ':lua require"plugins.fzf".file_under_coursor_all()<cr>')

u.map('n', '<space>ft', ':lua require"plugins.fzf".ft()<cr>')
u.map('v', '<space>fd', ':lua require"plugins.fzf".select_db()<cr>')
u.map('n', '<space>fd', ':lua require"plugins.fzf".select_db()<cr>')

u.map('n', '<space>gr', ':Rg<cr>')
u.map('n', '<space>gw', ':Rg <cword><cr>')
u.map('v', '<space>gw', '"ay :Rg <c-r>a<cr>')

u.map('n', '<space>fn', ':execute(":FZFFreshMru " . g:fzf_preview)<cr>')
u.map('n', '<space>fm', [[:lua require('fzf_mru.mru').display({branch = true})<cr>]])
u.map('n', '<space>fM', [[:lua require('fzf_mru.mru').display()<cr>]])
u.map('n', '<space>fb', ':FZFBuffers<cr>')

cmd([[command! -nargs=* -bang -complete=dir Rg lua require'plugins.fzf'.rg('<bang>' == '!',<q-args>)]])
cmd([[command! -nargs=* -bang -complete=dir Rgg lua require'plugins.fzf'.grep('<bang>' == '!',<q-args>)]])

function f.rg(raw, params)
  params = l.fzf_rg_params(raw, params)
  print(":rg -i " .. params)
  local options = { source = 'rg --vimgrep --color=always -i '  .. params,
    sink = 'l.from_grep_format',
    options = '--ansi --prompt "Rg> " ' .. l.process_params({}, true),
  }
  l.fzf_run(options)
end

function f.grep(raw, params)
  params = l.fzf_rg_params(raw, params)
  print(':grep -i ' .. params)
  cmd(':grep -i ' .. params)
end

function f.git_ls(...)
    local options = {
        source = 'git-ls',
        sink = 'l.git_ls',
        options = '--ansi --prompt "Git> " ' .. l.process_params({...}, true),
    }
    l.fzf_run(options)
end

function l.git_ls(line)
    local file, _ = string.gsub(' ' .. line, '^......(.*)', '%1')
    cmd('e ' .. file)
end

function f.loclist()
    local options = {
        source = l.get_loclist(),
        sink = 'l.from_grep_format',
        options = '--ansi --prompt "LocList> " ' .. l.process_params({}, true),
    }
    l.fzf_run(options)
end

function l.get_loclist()
  local result = {}
  local list = fn.getloclist(0)
  for _, row in ipairs(list) do
    local file = fn.bufname(row.bufnr)
    local line = file .. ':' .. row.lnum .. ':' .. row.col .. ':' .. row.text
    result[#result+1] = line
  end
  return result
end

function f.quickfix(word)
    local options = {
        source = l.get_quickfix(word),
        sink = 'l.from_grep_format',
        options = '--ansi --prompt "QuickFix> " ' .. l.process_params({}, true),
    }
    l.fzf_run(options)
end

function l.get_quickfix(word)
  local result = {}
  local list = fn.getqflist()
  for _, row in ipairs(list) do
    local file = fn.bufname(row.bufnr)
    local c = {
      purple = '\27[35m',
      gray = '\27[38m',
      green = '\27[32m',
    }
    local text = row.text
    if word then
      text = text:gsub(word, '\27%[3;31m%1\27%[0m')
    end
    local line = c.purple .. file .. c.gray .. ':' .. c.green .. row.lnum
      .. c.gray .. ':' .. row.col .. ':' .. c.gray .. text
    result[#result+1] = line
  end
  return result
end

function l.from_grep_format(line)
  local match = {line:match('(.-):(.-):(.-):.*')}
  cmd('e ' .. match[1])
  fn.cursor(match[2], match[3])
end

function f.files(...)
    local options = {
        options = '--prompt "Files> " ' .. l.process_params({...}, true),
    }
    l.fzf_run(options)
end

function f.all_files(...)
    local options = {
        source = 'rg -u --files',
        options = '--prompt "All Files> " ' .. l.process_params({...}, true),
    }
    l.fzf_run(options)
end

function f.totaly_all_files(...)
    local options = {
        source = 'rg -uu --files',
        options = '--prompt "All Files> " ' .. l.process_params({...}, true),
    }
    l.fzf_run(options)
end

function f.dotfiles(...)
    local options = {
        dir = os.getenv('DOTFILES'),
        options = '--prompt "Dot files> " ' .. l.process_params({...}, true),
        sink = 'e'
    }

    l.fzf_run(options)
end

function f.templates(...)
    local options = {
        dir = os.getenv('DOTFILES') .. '/vim/mytemplates',
        options = '--prompt "Templates> " ' .. l.process_params({...}, true),
        sink = 'e'
    }

    l.fzf_run(options)
end

function f.snippets(...)
    local options = {
        dir = os.getenv('DOTFILES') .. '/vim/mysnippets',
        options = '--prompt "Snippets> " ' .. l.process_params({...}, true),
        sink = 'e'
    }

    l.fzf_run(options)
end

function f.nvim_config(...)
    local options = {
        source = [[
            rg --files \
            config/nvim/init.vim \
            config/nvim/init.lua \
            config/nvim/config   \
            vim/plugin/          \
            config/nvim/lua/
        ]],
        dir = os.getenv('DOTFILES'),
        options = '--prompt "Nvim files> " ' .. l.process_params({...}, true),
        sink = 'e'
    }

    l.fzf_run(options)
end

function f.file_under_coursor()
  local file = u.string_under_coursor()
  file = file:gsub('[~%.\\/]', ' ')
  f.files(u.trim_string(file))
end

function f.file_under_coursor_all()
  local file = u.string_under_coursor()
  file = file:gsub('[~%.\\/]', ' ')
  f.all_files(u.trim_string(file))
end

function f.ft(...)
    local options = {
        source = { "css", "elixir", "go", "html", "javascript",
            "javascript.jsx", "php", "php.phtml", "ruby", "scss",
            "sh", "vim", "xml", "lua"
        },
        sink = 'l.ft',
        options = '--print-query --prompt "FileType> " ' .. l.process_params({...}, true),
    }
    l.fzf_run(options)
end

function l.ft(line)
  vim.bo.ft = line
end

function f.select_db(...)
  local options = {
    source = fn['db#url_complete']('g:'),
    options = '--prompt "Select DB> " ' .. l.process_params({...}, true),
    sink = 'l.select_db',
  }
  l.fzf_run(options)
end

function l.select_db(line)
    b.db = api.nvim_eval(line)
    b.db_selected = line
    vim.schedule(function()
      fn['db#adapter#ssh#create_tunnel'](b.db)
    end)
end

-- FZFLuaSink is workaround to use lua functions as a sink, have no better idea
cmd([[command! -nargs=* FZFLuaSink :lua require'plugins.fzf'.sink(<q-args>)]])

function f.sink(args)
    local callback, _ = string.gsub(args, '(.-):.*', '%1')
    local line, _ = string.gsub(args, '.-:.(.*)', '%1')

    return l[callback](line)
end

-- last search command, so we can repeat it when call Rg with no arguments
l.last_rg_params = ''

function l.fzf_run(options)
    options = u.extend_table(u.copy_table(g.fzf_layout), options)
    if not options.sink then
        options.sink = 'e'
    elseif string.match(options.sink, '^l%.') then
        local sink_fn = string.gsub(options.sink, '^l%.(.*)', '%1')
        options.sink = 'FZFLuaSink ' .. sink_fn .. ':'
    end
    if not options.source then
        options.source = 'rg --files'
    end
    fn['fzf#run'](fn['fzf#wrap'](options))
end

function l.process_params(params, preview)
    params = params or {}
    preview = preview or false
    params = table.concat(params, ' ')
    if string.len(params) > 0 and not string.match(params, '^-.*') then
      params = ' -q ' .. vim.fn.shellescape(params)
    end

    if preview == true then
        return (g.fzf_preview or '') .. ' ' .. params
    else
        return params
    end
end

function l.fzf_rg_process(query, escape)
  if escape then
    return fn.shellescape(fn.escape(query, '\\'))
  else
    return query
  end
end

function l.fzf_rg_params(araw, aparams)
  aparams = u.split_string(aparams)
  if #aparams == 0 then
    return l.last_rg_params
  end

  local ldir = aparams[#aparams]
  local lsuffix = ''
  if string.match(ldir, '/$') and fn.isdirectory(ldir) > 0 then
    table.remove(aparams, #aparams)
    lsuffix = ' ' .. ldir
  end

  local lflags = {}
  local lquery = {}

  local lquery_started = false
  for _, lparam in ipairs(aparams) do
    if not lquery_started and string.match(lparam, '^-') then
      table.insert(lflags, lparam)
    else
      lquery_started = true
      table.insert(lquery, lparam)
    end
  end

  lquery = fn.join(lquery, ' ')
  lflags = fn.join(lflags, ' ')

  local lquote = false
  if (not araw) then
    lquote = not string.match(lquery, '^["\']')
  else
    lquote = not araw
  end

  lquery = l.fzf_rg_process(lquery, lquote)

  l.last_rg_params = lflags .. ' ' .. lquery .. lsuffix
  return l.last_rg_params
end

return f
