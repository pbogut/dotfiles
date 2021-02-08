local u = require('utils')
local g = vim.g

g.ale_lint_on_text_changed = 'never'
g.ale_lint_on_enter = 0
g.ale_php_phpcs_executable = os.getenv('HOME') .. '/.bin/phpcs'
g.ale_php_phpcs_use_global = 1
-- there is more we have bigger problem, limit should save my vim from crashing
g.ale_max_signs = 50
g.ale_disable_lsp = 1
g.ale_lint_on_save = 1
-- to disable autocommand set up by ale
g.ale_lint_on_text_changed = 'never'
g.ale_command_wrapper = 'nice -n15'

g.ale_sign_error = ''
g.ale_sign_warning = ''

g.ale_virtualtext_cursor = 1

g.ale_virtualtext_prefix = '   '
g.ale_sign_column_always = 1

g.ale_echo_msg_error_str = 'E'
g.ale_echo_msg_warning_str = 'W'
g.ale_echo_msg_format = '[%severity%][%linter%] %s'

u.augroup('x_ale', {
  VimEnter = {
    {
      '*',
      function()
        -- highlights
        u.highlights({
          ALEVirtualTextInfo = {gui='italic'},
          ALEErrorSign = {guibg = '%073642', guifg = '#dc322f'},
          ALEWarningSign = {guibg = '%073642', guifg = '#d33682'},
          ALEVirtualTextError = {guibg = '%073642', guifg = '#dc322f', gui = 'italic'},
          ALEVirtualTextWarning = {guibg = '%073642', guifg = '#d33682', gui = 'italic'},
          ALEVirtualTextStyleError = {guibg = '%073642', guifg = '#dc322f', gui = 'italic'},
          ALEVirtualTextStyleWarning = {guibg = '%073642', guifg = '#d33682', gui = 'italic'},
        })
      end
    },
  },
})
