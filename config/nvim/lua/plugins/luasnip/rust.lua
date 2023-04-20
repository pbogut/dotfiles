local ls = require('luasnip')
local fmt = require('luasnip.extras.fmt').fmt
local s = ls.s

ls.add_snippets('rs', {
  s(
    'stdin',
    fmt(
      [[
      let mut lines = std::io::stdin().lines();
      while let Some(Ok(line)) = lines.next() {{
      	println!("{{}}", line);
      }}
      ]],
      {}
    )
  ),
})
