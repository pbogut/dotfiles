local u = require('utils')
local g = vim.g
local fn = vim.fn

g.ale_lint_on_text_changed = 'never'
g.ale_lint_on_enter = 0
g.ale_php_phpcs_executable = os.getenv('HOME') .. '/.bin/phpcs'
g.ale_php_phpcs_use_global = 1
-- there is more we have bigger problem, limit should save my vim from crashing
g.ale_max_signs = 50
g.ale_sign_priority = 2
g.ale_disable_lsp = 1
g.ale_lint_on_save = 1
-- to disable autocommand set up by ale
g.ale_lint_on_text_changed = 'never'
g.ale_command_wrapper = 'nice -n15'

g.ale_sign_error = g.icon.error
g.ale_sign_warning = g.icon.warning
g.ale_sign_info = g.icon.info

g.ale_virtualtext_cursor = 1

g.ale_virtualtext_prefix = '    ■ '
g.ale_sign_column_always = 1

g.ale_echo_msg_error_str = 'E'
g.ale_echo_msg_warning_str = 'W'
g.ale_echo_msg_format = '[%severity%][%linter%] %s'

if fn.filereadable('phpmd.xml') > 0 then
  g.ale_php_phpmd_ruleset = 'phpmd.xml'
end

u.augroup('x_ale', {
  VimEnter = {
    {
      '*',
      function()
        -- highlights
        u.highlights({
          ALEVirtualTextInfo = {gui='none'},
          ALEErrorSign = {guibg = '#073642', guifg = '#dc322f', gui = 'none'},
          ALEWarningSign = {guibg = '#073642', guifg = '#268bd2', gui = 'none'},
          ALEVirtualTextError = {guibg = '#073642', guifg = '#268bd2', gui = 'none'},
          ALEVirtualTextWarning = {guibg = '#073642', guifg = '#268bd2', gui = 'none'},
          ALEVirtualTextStyleError = {guibg = '#073642', guifg = '#268bd2', gui = 'none'},
          ALEVirtualTextStyleWarning = {guibg = '#073642', guifg = '#268bd2', gui = 'none'},
        })
      end
    },
  },
})
