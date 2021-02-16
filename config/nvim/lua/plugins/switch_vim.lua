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
l.switch_php_class_string = { -- one way ticket, why would you use string!?
  ['create([\'"]\\\\\\=\\([a-zA-Z0-9_\\\\]*\\)[\'"])'] = 'create(\\\\\\1::class)',
  ['make([\'"]\\\\\\=\\([a-zA-Z0-9_\\\\]*\\)[\'"])'] = 'make(\\\\\\1::class)',
  ['get([\'"]\\\\\\=\\([a-zA-Z0-9_\\\\]*\\)[\'"])'] = 'get(\\\\\\1::class)',
}
l.switch_php_laravel_facade = {
  ['use \\([A-Z][A-Za-z]*\\);'] = 'use Illuminate\\\\Support\\\\Facades\\\\\\1;',
  ['use Illuminate\\\\Support\\\\Facades\\\\\\([A-Z][A-Za-z]*\\);'] = 'use \\1;',
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
l.switch_words_tf = {
  ['\\<true\\>'] =   'false',
  ['\\<false\\>'] = 'true',
}
l.switch_words_lr = {
  ['\\<left\\>'] =   'right',
  ['\\<right\\>'] = 'left',
}

local function addDefinition(data)
  local current = b.switch_custom_definitions or {}
  b.switch_custom_definitions = u.merge_tables(current, data)
end

u.augroup('x_switch', {
    FileType = {
      {'*', function()
          addDefinition({
            l.switch_words_tf,
            l.switch_words_lr,
          })
      end},
      {'blade', function()
          addDefinition({
            l.switch_blade_echo,
            l.switch_quotes,
          })
      end},
      {'php', function()
          addDefinition({
            l.switch_c_like_if,
            l.switch_c_like_while,
            l.switch_php_class_string,
            l.switch_php_array,
            l.switch_php_comment,
            l.switch_php_scope,
            l.switch_php_magento_dispatch_event,
            l.switch_php_laravel_facade,
            l.switch_quotes,
          })
      end},
      {'javascript', function()
          addDefinition({
            l.switch_c_like_if,
            l.switch_quotes,
          })
      end},
      {'javascript.jsx', function()
          addDefinition({
            l.switch_c_like_if,
            l.switch_quotes,
          })
      end},
      {'elixir', function()
          addDefinition({
            l.switch_elixir_assert,
            l.switch_elixir_map,
            l.switch_quotes,
          })
      end},
      {'markdown,md', function()
          addDefinition({
            l.switch_md_checkbox,
            l.switch_quotes,
          })
      end},
      {'vimwiki', function()
          addDefinition({
            l.switch_vimwiki_checkbox,
            l.switch_quotes,
          })
      end},
      {'email', function()
          addDefinition({
            l.switch_quotes,
          })
      end},
      {'diff', function()
          addDefinition({
            l.switch_diffline ,
          })
      end},
    }
})
