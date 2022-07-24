local shared = require('projector.shared')
local templates = require('projector.templates')

local cmd = vim.cmd
local fn = vim.fn

local M = {}

local function generate_file(path, template_name)
  cmd.edit(path)
  fn.system('mkdir -p ' .. fn.expand('%:h'))

  local stop = fn.line('$')

  if template_name then
    vim.api.nvim_buf_set_lines(0, 0, stop, false, {})
    templates.file_template(template_name)
  end
  cmd('silent! noautocmd w!')
end

local function replace_variables(text, vars)
  for var, val in pairs(vars) do
    text = text:gsub('%{' .. var .. '%}', val)
  end
  return text
end

function M.generator_list(lead)
  local result = {}
  local generators = shared.get_config('generators', {})
  for name, _ in pairs(generators) do
    if name:sub(1, lead:len()) == lead then
      table.insert(result, name)
    end
  end

  return result
end

function M.generate(generator_name)
  local generators = shared.get_config('generators', {})
  if not generators[generator_name] then
    print('Generator ' .. generator_name .. ' not found')
    return
  end
  local generator = generators[generator_name]
  local summary = { 'Generator name: ' .. generator_name }

  local variables = {}

  if generator.variables then
    for _, vardef in pairs(generator.variables) do
      variables[vardef.name] = vim.fn.input((vardef.prompt or vardef.name) .. ': ')
    end
  end
  if generator.new then
    summary[#summary + 1] = ''
    summary[#summary + 1] = 'New files:'
    for _, new in pairs(generator.new) do
      local file = replace_variables(new.file, variables)
      if fn.filereadable(file) > 0 then
        summary[#summary + 1] = '  SKIP: ' .. file
        summary[#summary + 1] = '    - already exists'
      else
        summary[#summary + 1] = '  ' .. file
        generate_file(file, new.template)
      end
    end
  end
  if generator.update then
    summary[#summary + 1] = ''
    summary[#summary + 1] = 'Updated files:'
    for _, update in pairs(generator.update) do
      local file = replace_variables(update.file, variables)
      cmd.edit(file)
      local stop = fn.line('$')
      local lines = fn.getline(0, stop)
      local errors = require('projector.update').errors(lines, update)

      if #errors == 0 then
        local new_lines = require('projector.update').update(lines, update)
        summary[#summary + 1] = '  ' .. file
        vim.api.nvim_buf_set_lines(0, 0, stop, false, new_lines)
      else
        summary[#summary + 1] = '  SKIP: ' .. file
        for _, error in pairs(errors) do
          summary[#summary + 1] = '    - ' .. error
        end
      end
      cmd('silent! noautocmd w!')
    end
  end
  if generator.cmd then
    summary[#summary + 1] = ''
    summary[#summary + 1] = 'Commands run:'
    for _, command in pairs(generator.cmd) do
      summary[#summary + 1] = '  ' .. command
    end
    cmd('belowright 20split')
    cmd.enew()
    local command = table.concat(generator.cmd, '; ')
    fn.termopen(command, {
      on_exit = function()
        cmd.wincmd('q')
        cmd.enew()
        vim.bo.buftype = 'nofile'
        vim.bo.bufhidden = 'hide'
        vim.bo.swapfile = false
        vim.api.nvim_buf_set_lines(0, 0, 0, false, summary)
      end,
    })
  else
    cmd.enew()
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'hide'
    vim.bo.swapfile = false
    vim.api.nvim_buf_set_lines(0, 0, 0, false, summary)
    -- hack coz I have some issues on 5th line in last buffer
    -- running terminal this way removes issue for som reason
    fn.termopen('', {
      on_exit = function()
        cmd.wincmd('q')
      end,
    })
  end
  -- print(vim.inspect(generators[generator_name]))
end

_G.projector = _G.projector or {}
_G.projector.gen_completion = M.generator_list

return M
