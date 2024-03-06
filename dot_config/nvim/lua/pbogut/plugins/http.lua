---@type LazyPluginSpec
return {
  'nicwest/vim-http',
  cmd = { 'Http', 'HttpShowCurl', 'HttpShowRequest', 'HttpClean', 'HttpAuth' },
  keys = {
    { '<space>H', '<cmd>Http<cr>', desc = 'Run Http' },
  },
  init = function()
    vim.g.vim_http_split_vertically = 1
    vim.g.vim_http_tempbuffer = 1
    vim.g.vim_http_right_below = 1
  end,
  config = function()
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('x_vim_http', { clear = true }),
      pattern = '*.response.*.http',
      callback = function()
        vim.keymap.set('n', 'q', '<cmd>bd<cr>', { buffer = true })
        vim.schedule(function()
          vim.o.number = true
          -- format json output
          if vim.fn.executable('jq') == 1 then
            local format = false
            local response_line = 0
            for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, true)) do
              if line:lower():match('^content%-type%: application%/json') then
                format = true
              end
              if line:match('^$') then
                response_line = i + 1
                break
              end
            end
            if format then
              vim.cmd(response_line .. ',$!jq .')
            end
          end
        end)
      end,
    })
  end,
}
