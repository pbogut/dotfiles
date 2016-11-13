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
      \       "type": "test"
      \     },
      \   },
      \   "mix.exs&web/": {
      \     "web/*.ex": {
      \       "alternate": "test/{}_test.exs"
      \     },
      \     "test/*_test.exs": {
      \       "alternate": "web/{}.ex",
      \       "type": "test"
      \     },
      \   },
      \ }
