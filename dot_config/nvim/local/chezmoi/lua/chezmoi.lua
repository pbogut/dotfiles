local chezmoi_telescope = require('chezmoi.telescope')
local chezmoi_src = os.getenv('HOME') .. "/.local/share/chezmoi"

vim.keymap.set('n', '<plug>(ts-chezmoi-files)', chezmoi_telescope.chezmoi_files)

local function trim_string(text)
  text, _ = text:gsub('^%s*(.-)%s*$', '%1')
  return text
end

vim.api.nvim_create_user_command('ChezmoiAdd', function(_)
  local file = vim.fn.expand('%:p')
  if file:sub(1, #chezmoi_src) == chezmoi_src then
    local src = vim.fn.system('chezmoi target-path ' .. vim.fn.shellescape(file))
    src = trim_string(src)
    vim.cmd('rightbelow 20split enew')
    vim.cmd('terminal chezmoi apply ' .. vim.fn.shellescape(src))
    vim.cmd.startinsert()
  end
end, {})

local augroup = vim.api.nvim_create_augroup('pb_chezmoi', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
  group = augroup,
  pattern = chezmoi_src .. '/*,*/chezmoi-encrypted/*',
  callback = function()
    if vim.b.chezmoi then
      return
    end
    vim.b.chezmoi = true

    local source_path = vim.fn.expand('%:p')

    vim.api.nvim_create_autocmd('BufWritePost', {
      group = augroup,
      buffer = vim.fn.bufnr(),
      callback = function()
        if not vim.b.chezmoi then
          return
        end

        if not vim.b.chezmoi_target_path then
          vim.b.chezmoi_target_path = trim_string(
            vim.fn.system('chezmoi target-path ' .. vim.fn.shellescape(source_path))
          )
        end

        local target_path = vim.b.chezmoi_target_path
        if not target_path or target_path == '' then
          vim.b.chezmoi = false
          return
        end

        local target_base_name = target_path:gsub('.*%/([^%/]*)$', '%1')

        vim.fn.jobstart('chezmoi edit --apply ' .. vim.fn.shellescape(target_path), {
          env = {
            CHEZMOI_NVIM_FILE = source_path,
            CHEZMOI_NVIM = 'apply',
            EDITOR = 'chezmoi-nvim',
          },
          on_exit = function(_, code)
            if code ~= 0 then
              vim.notify(
                'Failed to apply changes for ' .. target_base_name .. ' file.',
                vim.log.levels.ERROR,
                { title = 'Chezmoi' }
              )
            else
              vim.notify(
                'Changes for ' .. target_base_name .. ' file has been applied.',
                vim.log.levels.INFO,
                { title = 'Chezmoi' }
              )
            end
          end,
        })
      end,
    })
  end,
})
