" switch between class and test file
let g:projectionist_heuristics = {}
" composer projects
let g:projectionist_heuristics["composer.json"] =
      \   {
      \     "*": {
      \       "project_root": 1
      \     },
      \   }
" laravel
let g:projectionist_heuristics["artisan&composer.json"] =
      \   {
      \     "*.php": {
      \       "console": "php artisan tinker"
      \     },
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
      \   }
" elixir
let g:projectionist_heuristics["mix.exs"] =
      \   {
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
      \   }
" elixir phoenix
let g:projectionist_heuristics["mix.exs&web/"] =
      \   {
      \     "*": {
      \       "start": "iex --sname phoenix -S mix phoenix.server",
      \       "console": "iex --sname relp",
      \     },
      \     "web/*.ex": {
      \       "alternate": "test/{}_test.exs"
      \     },
      \     "test/*_test.exs": {
      \       "alternate": "web/{}.ex",
      \       "type": "test",
      \     },
      \   }
" codeception
let g:projectionist_heuristics["codeception.yml"] =
      \   {
      \     "tests/unit/*Test.php": {
      \       "alternate": ["app/{}.php", "lib/{}.php"],
      \       "template": [
      \          "<?php",
      \          "namespace {dirname|capitalize|backslash};",
      \          "",
      \          "",
      \          "class {basename|capitalize}Test extends \\Codeception\\Test\\Unit",
      \          "{open}",
      \          "\t/**",
      \          "\t* @var \UnitTester",
      \          "\t*/",
      \          "\tprotected $tester;",
      \          "",
      \          "\tprotected function _before()",
      \          "\t{open}",
      \          "\t{close}",
      \          "",
      \          "\tprotected function _after()",
      \          "\t{open}",
      \          "\t{close}",
      \          "",
      \          "\t// tests",
      \          "\tpublic function testMe()",
      \          "\t{open}",
      \          "",
      \          "\t{close}",
      \          "{close}",
      \       ],
      \       "type": "test"
      \     },
      \     "tests/**/*Cept.php": {
      \       "type": "test"
      \     },
      \     "tests/**/*Cest.php": {
      \       "type": "test"
      \     },
      \     "app/*.php": {
      \       "alternate": "tests/unit/{}Test.php"
      \     },
      \     "lib/*.php": {
      \       "alternate": "tests/unit/{}Test.php"
      \     },
      \   }
