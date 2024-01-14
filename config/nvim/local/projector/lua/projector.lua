--[[ projector module -- its like... projectionist I guess ]]

--[[ handles themplates and alternate files based on some patterns
     unlike projectionist it uses full patternmatching (lua one) so you have
     more freedom in configuration
     alternate file uses fzf if more then one candidate returned
     templates can be snippy snippets or files with placeholders ]]

local generators = require('projector.generators')
local alternates = require('projector.alternates')
local templates = require('projector.templates')
local shared = require('projector.shared')
local u = require('pbogut.utils')

local t = u.termcodes
local g = vim.g
local cmd = vim.cmd

local a = {}
local l = {}

function a.setup(opts)
  shared.setup(opts)
  templates.setup(opts)
end

function a.ultisnip_template(name)
  cmd('silent! normal! i_t' .. name .. t('<c-r>=UltiSnips#ExpandSnippet()<cr>'))
  if not g.ulti_expand_res or g.ulti_expand_res == 0 then
    cmd('silent! undo')
  end
  return g.ulti_expand_res and g.ulti_expand_res ~= 0
end

-- local functions
function l.init_project()
  local init = shared.get_config('project_init')
  if type(init) == 'function' then
    return init()
  end
  if type(init) == 'table' then
    for _, fn in pairs(init) do
      fn()
    end
  end
end

function l.check_file(relative, pattern)
  return relative:match(pattern)
end

vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('x_projector_pr_init', { clear = true }),
  callback = l.init_project,
})

a.get_config = shared.get_config
a.go_alternate = alternates.go_alternate
a.do_template = templates.do_template
a.generate = generators.generate
a.template_command = templates.template_command

_G.projector = _G.projector or {}
_G.projector.temp_completion = templates.template_list
_G.projector.placeholder = templates.process_placeholder
_G.projector.get_config = shared.get_config

_G.projector.gen_completion = generators.generator_list

return a
