local tsj = require('treesj')

local langs = {
  php = {
    arguments = {
      both = {
        last_separator = false,
      },
    },
  },
  elixir = {
    arguments = {
      both = {
        separator = ',',
        last_separator = false,
      },
    },
    tuple = {
      both = {
        separator = ',',
        last_separator = false,
      },
    },
    keywords = {
      both = {
        separator = ',',
        last_separator = false,
        non_bracket_node = true,
        recursive = false,
      },
    },
    map_content = {
      both = {
        separator = ',',
        last_separator = false,
        non_bracket_node = true,
      },
    },
  },
}

tsj.setup({
  use_default_keymaps = false,
  check_syntax_error = false,
  max_join_length = 120,
  cursor_behavior = 'hold',
  notify = true,
  langs = langs,
  dot_repeat = true,
})

vim.keymap.set('n', 'gS', tsj.split, { silent = true })
vim.keymap.set('n', 'gJ', tsj.join, { silent = true })
