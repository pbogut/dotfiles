local u = require('utils')
local g = vim.g
local b = vim.b
local l = {}

g.switch_custom_definitions = {
  {
    ['\\(===\\)'] = '==',
    ['\\(==\\)'] =  '===',
  },
  {
    ['\\(!==\\)'] = '!=',
    ['\\(!=\\)'] =  '!==',
  },
  {
    ['show'] = 'hide',
    ['hide'] =  'show',
  },
}
l.switch_c_like_if = {
  ['if (true || (\\(.*\\)))'] =          'if (false && (\\1))',
  ['if (false && (\\(.*\\)))'] =         'if (\\1)',
  ['if (\\%(true\\|false\\)\\@!\\(.*\\))'] = 'if (true || (\\1))',
}
l.switch_c_like_while = {
  ['while (true || (\\(.*\\)))'] =          'while (false && (\\1))',
  ['while (false && (\\(.*\\)))'] =         'while (\\1)',
  ['while (\\%(true\\|false\\)\\@!\\(.*\\))'] = 'while (true || (\\1))',
}
l.switch_php_scope = {
  ['\\<private\\>'] =   'protected',
  ['\\<protected\\>'] = 'public',
  ['\\<public\\>'] =    'private',
}
l.switch_php_array = {
  ['\\<array(\\(.*\\))'] =      '[\\1]',
  ['\\(\\s*\\|^\\)\\[\\(.*\\)\\]'] = '\\1array(\\2)',
}
l.switch_php_comment = {
  ['^\\(\\s*\\)/\\* \\(.*\\) \\*/$'] =      '\\1// \\2',
  ['^\\(\\s*\\)// \\(.*\\)'] = '\\1/* \\2 */',
}
l.switch_php_magento_dispatch_event = {
  ['Mage::dispatchEvent'] = '$this->_eventManager->dispatch',
  ['$this->_eventManager->dispatch'] = 'Mage::dispatchEvent',
}
l.switch_elixir_assert = {
  ['\\(assert\\)'] = 'refute',
  ['\\(refute\\)'] = 'assert',
}
l.switch_elixir_map = {
  ['\\<\\([a-zA-Z0-9_]*\\): \\([^,]*\\),'] =   '"\\1" => \\2,',
  ['"\\([a-zA-Z0-9_]*\\)" => \\([^,]*\\),'] = '\\1: \\2,',
}
l.switch_blade_echo = {
  ['{{\\(.\\{-}\\)}}'] =   '{!!\\1!!}',
  ['{!!\\(.\\{-}\\)!!}'] =   '{{\\1}}',
}
l.switch_md_checkbox = {
  ['\\[ \\]'] =   '[x]',
  ['\\[x\\]'] =   '[ ]',
}
l.switch_vimwiki_checkbox = {
  ['\\[ \\]'] = '[o]',
  ['\\[\\.\\]'] = '[o]',
  ['\\[o\\]'] = '[X]',
  ['\\[O\\]'] = '[X]',
  ['\\[X\\]'] = '[ ]',
}
l.switch_quotes = {
  ['"\\([^"]*\\)"'] = "'\\1'",
  ["'\\([^']*\\)'"] = '"\\1"',
}
l.switch_diffline = {
  ['^+'] = '-',
  ['^-'] = ' ',
  ['^\\s'] = '+',
}

u.augroup('x_switch', {
    FileType = {
      {'blade', function()
          b.switch_custom_definitions = {
            l.switch_blade_echo,
            l.switch_quotes,
          }
      end},
      {'php', function()
          b.switch_custom_definitions = {
            l.switch_c_like_if,
            l.switch_c_like_while,
            l.switch_php_array,
            l.switch_php_comment,
            l.switch_php_scope,
            l.switch_php_magento_dispatch_event,
            l.switch_quotes,
          }
      end},
      {'javascript', function()
          b.switch_custom_definitions = {
            l.switch_c_like_if,
            l.switch_quotes,
          }
      end},
      {'javascript.jsx', function()
          b.switch_custom_definitions = {
            l.switch_c_like_if,
            l.switch_quotes,
          }
      end},
      {'elixir', function()
          b.switch_custom_definitions = {
            l.switch_elixir_assert,
            l.switch_elixir_map,
            l.switch_quotes,
          }
      end},
      {'markdown,md', function()
          b.switch_custom_definitions = {
            l.switch_md_checkbox,
            l.switch_quotes,
          }
      end},
      {'vimwiki', function()
          b.switch_custom_definitions = {
            l.switch_vimwiki_checkbox,
            l.switch_quotes,
          }
      end},
      {'email', function()
          b.switch_custom_definitions = {
            l.switch_quotes,
          }
      end},
      {'diff', function()
          b.switch_custom_definitions = {
            l.switch_diffline ,
          }
      end},
    }
})
