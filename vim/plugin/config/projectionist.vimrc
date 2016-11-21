" switch between class and test file
" laravel
" elixir
" elixir phoenix
let g:projectionist_heuristics = {
      \   "artisan&composer.json": {
      \     "app/*.php": {
      \       "alternate": "tests/{}Test.php"
      \     },
      \     "lib/*.php": {
      \       "alternate": "tests/{}Test.php"
      \     },
      \     "tests/*Test.php": {
      \       "alternate": ["app/{}.php", "lib/{}.php"],
      \       "template": [
      \          "<?php\n",
      \          "class {capitalize|underscore|camelcase}Test extends TestCase",
      \          "{open}",
      \          "{close}",
      \       ],
      \       "type": "test"
      \     },
      \   },
      \   "mix.exs": {
      \     "lib/*.ex": {
      \       "alternate": "test/{}_test.exs"
      \     },
      \     "test/*_test.exs": {
      \       "alternate": "lib/{}.ex",
      \       "template": [
      \          "defmodule {camelcase|dot}Test do",
      \          "\tuse {dirname|camelcase|dot}",
      \          "end",
      \       ],
      \       "type": "test",
      \     },
      \   },
      \   "mix.exs&web/": {
      \     "*": {
      \       "start": "iex -S mix phoenix.server"
      \     },
      \     "web/*.ex": {
      \       "alternate": "test/{}_test.exs"
      \     },
      \     "test/*_test.exs": {
      \       "alternate": "web/{}.ex",
      \       "type": "test",
      \     },
      \   },
      \ }
