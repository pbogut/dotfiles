local command = vim.api.nvim_create_user_command
local M = {}

local function trim(s)
  return (s:gsub('^%s*(.-)%s*$', '%1'))
end

local function mk_tmp_dir()
  local handle = io.popen('mktemp -d')
  if not handle then
    return nil
  end
  local result = handle:read('*a')
  handle:close()
  return trim(result)
end

M.setup = function()
  command('PdfPreview', function()
    if not vim.b.mdpdf_file then
      local dirname = mk_tmp_dir()
      if dirname == nil then
        return vim.notify('Can not create temporary directory', vim.log.levels.ERROR, {
          title = 'mdpdf',
        })
      end
      vim.b.mdpdf_file = dirname .. '/output.pdf'
    end

    local augroup = vim.api.nvim_create_augroup('x_mdpdf', { clear = true })
    vim.api.nvim_create_autocmd('BufWritePost', {
      group = augroup,
      buffer = vim.fn.bufnr(),
      callback = function()
        if vim.b.mdpdf_file then
          vim.fn.jobstart({ 'mdtopdf', vim.fn.expand('%'), vim.b.mdpdf_file }, {
            detach = true,
          })
        end
      end,
    })

    vim.fn.jobstart({ 'mdtopdf', vim.fn.expand('%'), vim.b.mdpdf_file }, {
      detach = true,
      on_exit = function(_, code)
        if code == 0 then
          vim.fn.jobstart({ 'okular', vim.b.mdpdf_file })
        end
      end,
    })
  end, { nargs = '?', bang = true })
end

return M
