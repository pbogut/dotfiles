local compe = require('compe')
local u = require('utils')

compe.setup {
  enabled = true;
  autocomplete = true;
  debug = false;
  min_length = 1;
  preselect = 'enable';
  throttle_time = 80;
  source_timeout = 200;
  incomplete_delay = 400;
  max_abbr_width = 100;
  max_kind_width = 100;
  max_menu_width = 100;
  documentation = true;

  source = {
    path = true;
    buffer = true;
    calc = true;
    nvim_lsp = true;
    nvim_lua = true;
    tabnine = true;
    -- treesitter = true;
    vim_dadbod_completion = true;
    vsnip = true;
  };
}

u.map('i', '<c-space>', [[compe#complete()]], {expr = true});
u.map('i', '<cr>', [[compe#confirm('<cr>')]], {expr = true});
u.map('i', '<c-e>', [[compe#close('<c-e>')]], {expr = true});
