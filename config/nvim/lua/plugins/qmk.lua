local M = {}

local layouts = {
  dactyl_gaming = {
    'x x x x x x ',
    'x x x x x x ',
    'x x x x x x ',
    'x x x x x x ',
    '_ _ x x _ _ ',
    '_ _ _ _ x x',
    '_ _ _ _ x x',
    '_ _ _ _ x x',
    'x^x x^x x^x',
  },
  ergodox_pretty = {
    'x x x x x x x _ _ _ x x x x x x x',
    'x x x x x x x _ _ _ x x x x x x x',
    'x x x x x x _ _ _ _ _ x x x x x x',
    'x x x x x x x _ _ _ x x x x x x x',
    'x x x x x _ _ _ _ _ _ _ x x x x x',
    '_ _ _ _ _ x x _ _ _ x x _ _ _ _ _',
    '_ _ _ _ _ _ x _ _ _ x _ _ _ _ _ _',
    '_ _ _ _ x x x _ _ _ x x x _ _ _ _',
  },
  ergodox = {
    'x x x x x x x',
    'x x x x x x x',
    'x x x x x x _',
    'x x x x x x x',
    'x x x x x _ _',
    '_ _ _ _ _ x x',
    '_ _ _ _ _ _ x',
    '_ _ _ _ x x x',
    '_ _ _ _ _ _ _',
    'x x x x x x x',
    'x x x x x x x',
    '_ x x x x x x',
    'x x x x x x x',
    '_ _ x x x x x',
    'x x _ _ _ _ _',
    'x _ _ _ _ _ _',
    'x x x _ _ _ _',
  },
  kyria = {
    'x x x x x x _ _ _ _ _ x x x x x x',
    'x x x x x x _ _ _ _ _ x x x x x x',
    'x x x x x x x x _ x x x x x x x x',
    '_ _ _ x x x x x _ x x x x x _ _ _',
  },
}

local keymap_overrides = {
  qmk = {
    ['M_H'] = 'h bs',
    ['M_D'] = 'd del',
    ['M_CTL_QUOTE'] = "ctl '",
    ['M_CTL_ESC'] = 'ctl esc',
    ['M_CTL'] = 'ctl',
    ['M_ARR_L'] = '<-',
    ['M_ARR_R'] = '->',
    ['M_DARR_L'] = '<=',
    ['M_DARR_R'] = '=>',
    ['M_LSHIFT_BR'] = 'shf (',
    ['M_RSHIFT_BR'] = 'shf )',
    ['M_EX_EQ'] = '!=',
    ['M_GT_EQ'] = '>=',
    ['M_PIPE_GT'] = '|>',
    ['M_LT_PIPE'] = '<|',
    ['M_AND'] = '&&',
    ['M_OR'] = '||',
    ['M_LT_EQ'] = '<=',
    ['M_L1_TAB'] = 'l1 tab',
    ['M_L1_BSLS'] = 'l1 \\',
    ['M_FAR_RIGHT'] = 'mright',
    ['M_FAR_LEFT'] = 'mleft',
    ['KC_MEH'] = 'meh',
    ['MO(NAVI)'] = 'NAVI',
    ['kp_'] = '',
  },
  zmk = {
    ['&myt'] = '',
    ['&tl_tabtild PROG 0'] = 'PROG TAB ~',
    ['&tl_bslhmin PROG 0'] = 'PROG BSLH -',
    ['&sys_reset'] = 'RST',
    ['&bootloader'] = 'BOOT',
    ['&out OUT_'] = 'out ',
    ['&ext_power EP_'] = 'ep ',
    ['&tk'] = '',
    ['&tl'] = '',
    ['&hbs'] = 'h/bs',
    ['&ddel'] = 'd/del',
    ['&trans'] = '  ',
    ['&kp '] = '',
    ['&mo '] = '',
    ['&bt '] = '',
    ['N0'] = '0',
    ['N1'] = '1',
    ['N2'] = '2',
    ['N3'] = '3',
    ['N4'] = '4',
    ['N5'] = '5',
    ['N6'] = '6',
    ['N7'] = '7',
    ['N8'] = '8',
    ['N9'] = '9',
    ['BT_SEL'] = 'bt>',
    ['ESC'] = 'esc',
    ['K_PP'] = 'mply',
    ['LCTRL'] = 'lctrl',
    ['RCTRL'] = 'rctrl',
    ['LPAR'] = '(',
    ['RPAR'] = ')',
    ['LGUI'] = 'lgui',
    ['RGUI'] = 'rgui',
    ['SPACE'] = 'spc',
    ['RET'] = 'ret',
    ['FSLH'] = '/',
    ['BSLH'] = '\\',
    ['SEMI'] = ';',
    ['DOT'] = '.',
    ['COMMA'] = ',',
    ['RALT'] = 'ralt',
    ['LALT'] = 'lalt',
    ['LBKT'] = '[',
    ['RBKT'] = ']',
    ['LBRC'] = '{',
    ['RBRC'] = '}',
    ['MINUS'] = '-',
    ['UNDER'] = '_',
    ['PRCNT'] = '%%',
    ['TILDE'] = '~',
    ['HOME'] = 'home',
    ['END'] = 'end',
    ['PG_UP'] = 'pgup',
    ['PG_DN'] = 'pgdn',
    ['TAB'] = 'tab',
    ['LSHFT'] = 'lshft',
    ['RSHFT'] = 'rshft',
    ['BSPC'] = 'bs',
    ['CARET'] = '^',
    ['AMPS'] = '&',
    ['ASTRK'] = '*',
    ['EXCL'] = '!',
    ['AT'] = '@',
    ['DLLR'] = '$',
    ['HASH'] = '#',
    ['PLUS'] = '+',
    ['DEL'] = 'del',
    ['LEFT'] = 'left',
    ['RIGHT'] = 'right',
    ['UP'] = 'up',
    ['DOWN'] = 'down',
    ['SQT'] = "'",
    ['GRAVE'] = '`',
    ['EQUAL'] = '=',
  },
}

function M.config()
  local augroup = vim.api.nvim_create_augroup('x_qmk', { clear = true })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = augroup,
    pattern = 'kyria.keymap',
    callback = function()
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('x_qmk_autoformat', { clear = true }),
        buffer = 0,
        callback = function()
          vim.cmd.QMKFormat()
          vim.cmd.StripWhitespace()
        end,
      })

      vim.keymap.set('n', '<space>af', '<cmd>QMKFormat<cr>', { noremap = true, buffer = true })
      require('qmk').setup({
        name = 'LAYOUT_preonic_grid',
        comment_preview = {
          position = 'top',
          keymap_overrides = keymap_overrides.zmk,
        },
        auto_format_pattern = 'disable_this_shit',
        variant = 'zmk',
        layout = layouts.kyria,
      })
    end,
  })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = augroup,
    pattern = 'keymap.c',
    callback = function()
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('x_qmk_autoformat', { clear = true }),
        buffer = 0,
        callback = function()
          vim.cmd.QMKFormat()
          vim.cmd.StripWhitespace()
        end,
      })

      local fname = vim.fn.expand('%:p')
      if fname:match('ergodox%/keymap.c') then
        dump('ergo')
        require('qmk').setup({
          name = 'LAYOUT_ergodox',
          comment_preview = {
            position = 'top',
            keymap_overrides = keymap_overrides.qmk,
          },
          auto_format_pattern = 'disable_this_shit',
          variant = 'qmk',
          layout = layouts.ergodox,
        })
      end
      if fname:match('dactyl_gaming%/keymap.c') then
        dump('ergo')
        require('qmk').setup({
          name = 'LAYOUT',
          comment_preview = {
            position = 'top',
            keymap_overrides = keymap_overrides.qmk,
          },
          auto_format_pattern = 'disable_this_shit',
          variant = 'qmk',
          layout = layouts.dactyl_gaming,
        })
      end
      if fname:match('kyria%/keymap.c') then
        dump('kyria')
        require('qmk').setup({
          name = 'LAYOUT',
          comment_preview = {
            position = 'top',
            keymap_overrides = keymap_overrides.qmk,
          },
          auto_format_pattern = 'disable_this_shit',
          variant = 'qmk',
          layout = layouts.kyria,
        })
      end
    end,
  })
end

return M
