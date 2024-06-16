local chezmoi_telescope = require('chezmoi.telescope')
local home_path = os.getenv('HOME')
local chezmoi_src = home_path .. '/.local/share/chezmoi'

vim.keymap.set('n', '<plug>(ts-chezmoi-files)', chezmoi_telescope.chezmoi_files)

local e = vim.fn.shellescape

local function trim_string(text)
  text, _ = text:gsub('^%s*(.-)%s*$', '%1')
  return text
end

local function try_edit(source_path)
  if source_path:len() > 0 and source_path:sub(1, #chezmoi_src) == chezmoi_src then
    local bufnr = vim.fn.bufnr()
    vim.cmd.edit(source_path)
    -- remove original buffer, if it was changed it will error ¯\_(ツ)_/¯
    vim.api.nvim_buf_delete(bufnr, {})
    vim.notify('Opened chezmoi source version of the file.', vim.log.levels.INFO, { title = 'Chezmoi' })
  end
end

vim.api.nvim_create_user_command('ChezmoiApply', function(_)
  local file = vim.fn.expand('%:p')
  if file:sub(1, #chezmoi_src) == chezmoi_src and file:sub(1, #chezmoi_src + 2) ~= chezmoi_src .. '/.' then
    local src = vim.fn.system('chezmoi target-path ' .. e(file))
    src = trim_string(src)
    vim.cmd('rightbelow 20split enew')
    vim.cmd('terminal chezmoi apply ' .. e(src))
    vim.cmd.startinsert()
  end
end, {})

vim.api.nvim_create_user_command('ChezmoiAdd', function(opt)
  local file = vim.fn.expand('%:p')
  if not (file:sub(1, #chezmoi_src) == chezmoi_src and file:sub(1, #chezmoi_src + 2) ~= chezmoi_src .. '/.') then
    vim.cmd('rightbelow 20split enew')
    vim.cmd('terminal chezmoi add ' .. opt.args .. e(file))
    vim.cmd.startinsert()
  end
end, { nargs = '*' })

local managed_files = {}
-- collect all managed files and cache them in memory, seams to be better
-- this way than running command every time file is open
vim.fn.jobstart('chezmoi managed --exclude scripts,externals', {
  on_stdout = function(_, data)
    for _, line in pairs(data) do
      managed_files[home_path .. '/' .. line] = true
    end
  end,
  on_exit = function(_, code)
    if code ~= 0 then
      return
    end
    -- try current buffer after all managed files are collected
    local file_path = vim.fn.expand('%:p')
    if managed_files[file_path] then
      local source_path = trim_string(vim.fn.system('chezmoi source-path ' .. e(file_path)))
      try_edit(source_path)
    end
  end,
})

local augroup = vim.api.nvim_create_augroup('pb_chezmoi', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
  group = augroup,
  -- its kind of wide net, will have to optimise somehow
  pattern = home_path .. '/*',
  callback = function()
    local file_path = vim.fn.expand('%:p')

    -- if not managed nothing to do
    if not managed_files[file_path] then
      return
    end

    -- if already source file nothing to do
    if file_path:sub(1, #chezmoi_src) == chezmoi_src then
      return
    end

    vim.fn.jobstart('chezmoi source-path ' .. e(file_path), {
      on_stdout = function(_, data)
        local source_path = data[1]
        try_edit(source_path)
      end,
    })
  end,
})
vim.api.nvim_create_autocmd('BufEnter', {
  group = augroup,
  pattern = chezmoi_src .. '/*,*/chezmoi-encrypted/*',
  callback = function()
    if vim.b.chezmoi then
      return
    end
    vim.b.chezmoi = true

    local source_path = vim.fn.expand('%:p')
    local file_name = vim.fn.expand('%:t')

    if file_name:sub(1, 1) == '.' and source_path:sub(1, #chezmoi_src) == chezmoi_src then
      -- ignore dot files in chezmoi source
      vim.b.chezmoi = false
      return
    end

    vim.api.nvim_create_autocmd('BufWritePost', {
      group = augroup,
      buffer = vim.fn.bufnr(),
      callback = function()
        if not vim.b.chezmoi then
          return
        end

        if not vim.b.chezmoi_target_path then
          vim.b.chezmoi_target_path = trim_string(vim.fn.system('chezmoi target-path ' .. e(source_path)))
        end

        local target_path = vim.b.chezmoi_target_path
        if not target_path or target_path == '' then
          vim.b.chezmoi = false
          return
        end

        local target_base_name = target_path:gsub('.*%/([^%/]*)$', '%1')

        vim.fn.jobstart('chezmoi edit --apply ' .. e(target_path), {
          env = {
            CHEZMOI_NVIM_FILE = source_path,
            CHEZMOI_NVIM = 'apply',
            EDITOR = 'chezmoi-nvim',
          },
          on_exit = function(_, code)
            if code == 213 then
              vim.notify(
                'Nothing changed, file ' .. target_base_name .. ' has not been applied.',
                vim.log.levels.INFO,
                { title = 'Chezmoi' }
              )
            elseif code ~= 0 then
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
