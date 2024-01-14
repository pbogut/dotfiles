return {
  'andrewradev/switch.vim',
  keys = {
    { 'gs', '<plug>(Switch)', desc = 'Switch' },
  },
  init = function()
    vim.g.switch_mapping = ''
  end,
  config = function()
    local u = require('pbogut.utils')
    local g = vim.g
    local b = vim.b
    local l = {}

    g.switch_custom_definitions = {
      {
        ['\\(===\\)'] = '==',
        ['\\(==\\)'] = '===',
      },
      {
        ['\\(!==\\)'] = '!=',
        ['\\(!=\\)'] = '!==',
      },
      {
        ['show'] = 'hide',
        ['hide'] = 'show',
      },
    }
    l.switch_c_like_if = {
      ['if (true || (\\(.*\\)))'] = 'if (false && (\\1))',
      ['if (false && (\\(.*\\)))'] = 'if (\\1)',
      ['if (\\%(true\\|false\\)\\@!\\(.*\\))'] = 'if (true || (\\1))',
    }
    l.switch_c_like_while = {
      ['while (true || (\\(.*\\)))'] = 'while (false && (\\1))',
      ['while (false && (\\(.*\\)))'] = 'while (\\1)',
      ['while (\\%(true\\|false\\)\\@!\\(.*\\))'] = 'while (true || (\\1))',
    }
    l.switch_php_scope = {
      ['\\<private\\>'] = 'protected',
      ['\\<protected\\>'] = 'public',
      ['\\<public\\>'] = 'private',
    }
    l.switch_php_class_string = { -- one way ticket, why would you use string!?
      ['create([\'"]\\\\\\=\\([a-zA-Z0-9_\\\\]*\\)[\'"])'] = 'create(\\\\\\1::class)',
      ['make([\'"]\\\\\\=\\([a-zA-Z0-9_\\\\]*\\)[\'"])'] = 'make(\\\\\\1::class)',
      ['get([\'"]\\\\\\=\\([a-zA-Z0-9_\\\\]*\\)[\'"])'] = 'get(\\\\\\1::class)',
    }
    l.switch_php_laravel_array_helper = {
      ['array_add('] = 'Arr::add(',
      ['array_collapse('] = 'Arr::collapse(',
      ['array_divide('] = 'Arr::divide(',
      ['array_dot('] = 'Arr::dot(',
      ['array_except('] = 'Arr::except(',
      ['array_first('] = 'Arr::first(',
      ['array_flatten('] = 'Arr::flatten(',
      ['array_forget('] = 'Arr::forget(',
      ['array_get('] = 'Arr::get(',
      ['array_has('] = 'Arr::has(',
      ['array_last('] = 'Arr::last(',
      ['array_only('] = 'Arr::only(',
      ['array_pluck('] = 'Arr::pluck(',
      ['array_prepend('] = 'Arr::prepend(',
      ['array_pull('] = 'Arr::pull(',
      ['array_random('] = 'Arr::random(',
      ['array_set('] = 'Arr::set(',
      ['array_sort('] = 'Arr::sort(',
      ['array_sort_recursive('] = 'Arr::sortRecursive(',
      ['array_where('] = 'Arr::where(',
      ['array_wrap('] = 'Arr::wrap(',
      ['camel_case('] = 'Str::camel(',
      ['ends_with('] = 'Str::endsWith(',
      ['kebab_case('] = 'Str::kebab(',
      ['snake_case('] = 'Str::snake(',
      ['starts_with('] = 'Str::startsWith(',
      ['str_after('] = 'Str::after(',
      ['str_before('] = 'Str::before(',
      ['str_contains('] = 'Str::contains(',
      ['str_finish('] = 'Str::finish(',
      ['str_is('] = 'Str::is(',
      ['str_limit('] = 'Str::limit(',
      ['str_plural('] = 'Str::plural(',
      ['str_random('] = 'Str::random(',
      ['str_replace_array('] = 'Str::replaceArray(',
      ['str_replace_first('] = 'Str::replaceFirst(',
      ['str_replace_last('] = 'Str::replaceLast(',
      ['str_singular('] = 'Str::singular(',
      ['str_slug('] = 'Str::slug(',
      ['str_start('] = 'Str::start(',
      ['studly_case('] = 'Str::studly(',
      ['title_case('] = 'Str::title(',
      ['Arr::add('] = 'array_add(',
      ['Arr::collapse('] = 'array_collapse(',
      ['Arr::divide('] = 'array_divide(',
      ['Arr::dot('] = 'array_dot(',
      ['Arr::except('] = 'array_except(',
      ['Arr::first('] = 'array_first(',
      ['Arr::flatten('] = 'array_flatten(',
      ['Arr::forget('] = 'array_forget(',
      ['Arr::get('] = 'array_get(',
      ['Arr::has('] = 'array_has(',
      ['Arr::last('] = 'array_last(',
      ['Arr::only('] = 'array_only(',
      ['Arr::pluck('] = 'array_pluck(',
      ['Arr::prepend('] = 'array_prepend(',
      ['Arr::pull('] = 'array_pull(',
      ['Arr::random('] = 'array_random(',
      ['Arr::set('] = 'array_set(',
      ['Arr::sort('] = 'array_sort(',
      ['Arr::sortRecursive('] = 'array_sort_recursive(',
      ['Arr::where('] = 'array_where(',
      ['Arr::wrap('] = 'array_wrap(',
      ['Str::camel('] = 'camel_case(',
      ['Str::endsWith('] = 'ends_with(',
      ['Str::kebab('] = 'kebab_case(',
      ['Str::snake('] = 'snake_case(',
      ['Str::startsWith('] = 'starts_with(',
      ['Str::after('] = 'str_after(',
      ['Str::before('] = 'str_before(',
      ['Str::contains('] = 'str_contains(',
      ['Str::finish('] = 'str_finish(',
      ['Str::is('] = 'str_is(',
      ['Str::limit('] = 'str_limit(',
      ['Str::plural('] = 'str_plural(',
      ['Str::random('] = 'str_random(',
      ['Str::replaceArray('] = 'str_replace_array(',
      ['Str::replaceFirst('] = 'str_replace_first(',
      ['Str::replaceLast('] = 'str_replace_last(',
      ['Str::singular('] = 'str_singular(',
      ['Str::slug('] = 'str_slug(',
      ['Str::start('] = 'str_start(',
      ['Str::studly('] = 'studly_case(',
      ['Str::title('] = 'title_case(',
    }
    l.switch_php_laravel_facade = {
      ['use \\([A-Z][A-Za-z]*\\);'] = 'use Illuminate\\\\Support\\\\Facades\\\\\\1;',
      ['use Illuminate\\\\Support\\\\Facades\\\\\\([A-Z][A-Za-z]*\\);'] = 'use \\1;',
    }
    l.switch_php_array = {
      ['\\<array(\\(.*\\))'] = '[\\1]',
      ['\\(\\s*\\|^\\)\\[\\(.*\\)\\]'] = '\\1array(\\2)',
    }
    l.switch_php_comment = {
      ['^\\(\\s*\\)/\\* \\(.*\\) \\*/$'] = '\\1// \\2',
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
      ['\\<\\([a-zA-Z0-9_]*\\): \\([^,]*\\),'] = '"\\1" => \\2,',
      ['"\\([a-zA-Z0-9_]*\\)" => \\([^,]*\\),'] = '\\1: \\2,',
    }
    l.switch_blade_echo = {
      ['{{\\(.\\{-}\\)}}'] = '{!!\\1!!}',
      ['{!!\\(.\\{-}\\)!!}'] = '{{\\1}}',
    }
    l.switch_md_checkbox = {
      ['\\[ \\]'] = '[x]',
      ['\\[x\\]'] = '[ ]',
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
      ['\\<true\\>'] = 'false',
      ['\\<false\\>'] = 'true',
    }
    l.switch_words_lr = {
      ['\\<left\\>'] = 'right',
      ['\\<right\\>'] = 'left',
    }

    local function addDefinition(data)
      local current = b.switch_custom_definitions or {}
      b.switch_custom_definitions = u.merge_tables(current, data)
    end

    local augroup = vim.api.nvim_create_augroup('x_switch', { clear = true })
    local autocmds = {
      ['*'] = function()
        addDefinition({
          l.switch_words_tf,
          l.switch_words_lr,
        })
      end,
      blade = function()
        addDefinition({
          l.switch_blade_echo,
          l.switch_quotes,
        })
      end,
      php = function()
        addDefinition({
          l.switch_c_like_if,
          l.switch_c_like_while,
          l.switch_php_class_string,
          l.switch_php_array,
          l.switch_php_comment,
          l.switch_php_scope,
          l.switch_php_magento_dispatch_event,
          l.switch_php_laravel_facade,
          l.switch_php_laravel_array_helper,
          l.switch_quotes,
        })
      end,
      javascript = function()
        addDefinition({
          l.switch_c_like_if,
          l.switch_quotes,
        })
      end,
      ['javascript.jsx'] = function()
        addDefinition({
          l.switch_c_like_if,
          l.switch_quotes,
        })
      end,
      elixir = function()
        addDefinition({
          l.switch_elixir_assert,
          l.switch_elixir_map,
          l.switch_quotes,
        })
      end,
      ['markdown,md'] = function()
        addDefinition({
          l.switch_md_checkbox,
          l.switch_quotes,
        })
      end,
      vimwiki = function()
        addDefinition({
          l.switch_vimwiki_checkbox,
          l.switch_quotes,
        })
      end,
      email = function()
        addDefinition({
          l.switch_quotes,
        })
      end,
      diff = function()
        addDefinition({
          l.switch_diffline,
        })
      end,
    }
    for pattern, callback in pairs(autocmds) do
      vim.api.nvim_create_autocmd('FileType', {
        group = augroup,
        pattern = pattern,
        callback = callback,
      })
    end
  end,
}
