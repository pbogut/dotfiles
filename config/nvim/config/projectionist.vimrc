" transformations
let g:projectionist_transformations = get(g:, "projectionist_transformations", {})
function! g:projectionist_transformations.mag_add_block(input, o) abort
  return substitute(a:input, '\([^/]*/[^/]*\)', '\1/Block', '')
endfunction
function! g:projectionist_transformations.mag_rm_pool(input, o) abort
  return substitute(a:input, '^\(core/\|community/\|local/\)', '', '')
endfunction


" NOTES:
" Templates
" `skeleton` key is used for creating templates, @see vim/plugin/templates.vim
" for skeleton only it is also possible to use regexp to match files to do so
" prefix file pattern with r! and follow with vim regexp. =~# will be used to
" match pattern against relative file name

" mapping
noremap <space>ta :A<cr>

let s:space_4 =
      \   {
      \     "tabstop": 4,
      \     "shiftwidth": 4,
      \     "expandtab": 1
      \   }

let s:space_2 =
      \   {
      \     "tabstop": 2,
      \     "shiftwidth": 2,
      \     "expandtab": 1
      \   }

let s:tab_4 =
      \   {
      \     "tabstop": 4,
      \     "shiftwidth": 4,
      \     "expandtab": 0
      \   }

let s:tab_2 =
      \   {
      \     "tabstop": 2,
      \     "shiftwidth": 2,
      \     "expandtab": 0
      \   }

" heuristics
let s:magento_module =
      \   {
      \     "*": {
      \       "project_root": 1,
      \       "setlocal": s:space_4
      \     },
      \     "app/code/**/Block/*.php": {
      \       "skeleton": "magento_block",
      \       "alternate": "app/design/frontend/base/default/template/{mag_rm_pool|snakecase}.phtml"
      \     },
      \     "app/code/**/Helper/*.php": {
      \       "skeleton": "magento_helper",
      \     },
      \     "app/code/**/Model/Resource/*/Collection.php": {
      \       "skeleton": "magento_collection",
      \     },
      \     "app/code/**/Model/Resource/*.php": {
      \       "skeleton": "magento_resource",
      \     },
      \     "app/code/**/Model/*.php": {
      \       "skeleton": "magento_model",
      \     },
      \     "app/design/frontend/base/default/template/*.phtml": {
      \       "alternate": [
      \         "app/code/core/{camelcase|capitalize|mag_add_block}.php",
      \         "app/code/community/{camelcase|capitalize|mag_add_block}.php",
      \         "app/code/local/{camelcase|capitalize|mag_add_block}.php"
      \       ]
      \     }
      \   }
let s:magento2_module =
      \   {
      \     "*": {
      \       "project_root": 1,
      \       "setlocal": s:space_4,
      \     },
      \     "*.php": {
      \       "skeleton": "magento2_class",
      \       "priority": 9999999
      \     },
      \     "app/code/*/registration.php": {
      \       "skeleton": "magento2_registration"
      \     },
      \     'r!app/code/.*/Model/ResourceModel/.*/Collection.php': {
      \       "skeleton": "magento2_resource_model_collection",
      \       "priority": 100
      \     },
      \     'r!app/code/.*/Model/ResourceModel/.*/CollectionFactory.php': {
      \       "skeleton": "magento2_resource_model_collection_factory",
      \       "priority": 100
      \     },
      \     'r!app/code/.*/Model/ResourceModel/.*/DataProvider.php': {
      \       "skeleton": "magento2_resource_model_data_provider",
      \       "priority": 100
      \     },
      \     "r!app/code/.*/Model/ResourceModel/.*\.php": {
      \       "skeleton": "magento2_resource_model_entity",
      \       "priority": 200
      \     },
      \     "r!app/code/.*/Model/Source/.*\.php": {
      \       "skeleton": "magento2_resource_model_source",
      \       "priority": 100
      \     },
      \     "r!app/code/.*/Helper/.*\.php": {
      \       "skeleton": "magento2_helper",
      \       "priority": 100
      \     },
      \     "r!app/code/.*/Model/.*\.php": {
      \       "skeleton": "magento2_model_entity",
      \       "priority": 300
      \     },
      \     "app/code/**/view/adminhtml/layout/*_index.xml": {
      \       "skeleton": "magento2_layout_entity_index"
      \     },
      \     "app/code/**/view/adminhtml/layout/*_new.xml": {
      \       "skeleton": "magento2_layout_entity_new"
      \     },
      \     "app/code/**/view/adminhtml/layout/*_edit.xml": {
      \       "skeleton": "magento2_layout_entity_edit"
      \     },
      \     "app/code/**/view/adminhtml/ui_component/*_listing.xml": {
      \       "skeleton": "magento2_layout_ui_component_listing"
      \     },
      \     "app/code/**/view/adminhtml/ui_component/*_form.xml": {
      \       "skeleton": "magento2_layout_ui_component_form"
      \     },
      \     'r!app/code/.*/Controller/Adminhtml/.*/Index\.php': {
      \       "skeleton": "magento2_adminhtml_controller_index",
      \       "priority": 100
      \     },
      \     'r!app/code/.*/Controller/Adminhtml/.*/Edit\.php': {
      \       "skeleton": "magento2_adminhtml_controller_edit",
      \       "priority": 100
      \     },
      \     'r!app/code/.*/Controller/Adminhtml/.*/NewAction\.php': {
      \       "skeleton": "magento2_adminhtml_controller_new",
      \       "priority": 100
      \     },
      \     'r!app/code/.*/Controller/Adminhtml/.*/Save\.php': {
      \       "skeleton": "magento2_adminhtml_controller_save",
      \       "priority": 100
      \     },
      \     'r!app/code/.*/Controller/Adminhtml/.*\.php': {
      \       "skeleton": "magento2_adminhtml_controller",
      \       "priority": 1000
      \     },
      \     'r!app/code/.*/Controller/.*\.php': {
      \       "skeleton": "magento2_controller",
      \       "priority": 200
      \     },
      \     'r!app/code/.*/Observer/.*\.php': {
      \       "skeleton": "magento2_observer",
      \       "priority": 100
      \     },
      \     "app/code/*/etc/module.xml": {
      \       "skeleton": "magento2_module"
      \     },
      \     "app/code/*/etc/di.xml": {
      \       "skeleton": "magento2_di"
      \     },
      \     "app/code/*/etc/frontend/events.xml": {
      \       "skeleton": "magento2_events"
      \     },
      \     "app/code/*/etc/adminhtml/events.xml": {
      \       "skeleton": "magento2_events"
      \     },
      \     "app/code/*/etc/frontend/routes.xml": {
      \       "skeleton": "magento2_frontend_routes"
      \     },
      \     "app/code/*/etc/adminhtml/routes.xml": {
      \       "skeleton": "magento2_adminhtml_routes"
      \     }
      \  }
let s:composer =
      \   {
      \     "*": {
      \       "project_root": 1
      \     },
      \   }
let s:laravel =
      \   {
      \     "*": {
      \       "project": "laravel",
      \       "logwatch": "tail -n 500 -f storage/logs/*.log",
      \       "env": {'APP_ENV': 'testing'},
      \       "setlocal": s:space_4
      \     },
      \     "*.php": {
      \       "console": "php artisan tinker"
      \     },
      \     "app/*.php": {
      \       "alternate": [
      \         "tests/Unit/{}Test.php",
      \         "tests/Feature/{}Test.php"
      \       ],
      \       "skeleton": "laravel_class"
      \     },
      \     "app/Http/Controllers/*Controller.php": {
      \       "skeleton": "laravel_controller",
      \     },
      \     "tests/Unit/*Test.php": {
      \       "alternate": "app/{}.php",
      \       "skeleton": "laravel_test",
      \       "type": "test"
      \     },
      \     "tests/Feature/*Test.php": {
      \       "alternate": "app/{}.php",
      \       "skeleton": "laravel_test",
      \       "type": "test"
      \     },
      \     "app/Console/Commands/*.php": {
      \       "skeleton": "laravel_command",
      \       "type": "command"
      \     },
      \   }
let s:elixir =
      \   {
      \     "lib/*.ex": {
      \       "alternate": "test/{}_test.exs"
      \     },
      \     "test/*_test.exs": {
      \       "alternate": "lib/{}.ex",
      \       "skeleton": "test",
      \       "type": "test",
      \     },
      \     "*.exs": {
      \       "alternate": "{}_test.exs"
      \     },
      \     "*.ex": {
      \       "alternate": "{}_test.exs"
      \     },
      \     "*_test.exs": {
      \       "alternate": ["{}.exs", "{}.ex"],
      \       "skeleton": "test",
      \       "type": "test",
      \     },
      \   }
let s:phoenixframework =
      \   {
      \     "*": {
      \       "start": "iex --sname phoenix -S mix phoenix.server",
      \       "console": "iex --sname relp",
      \     },
      \     "*.exs": {
      \       "skeleton": "phoenix_skel",
      \     },
      \     "*.ex": {
      \       "skeleton": "phoenix_skel",
      \     },
      \     "*_view.ex": {
      \       "skeleton": "phoenix_view",
      \     },
      \     "lib/*.ex": {
      \       "alternate": "test/{}_test.exs",
      \     },
      \     "web/*.ex": {
      \       "alternate": "test/{}_test.exs",
      \     },
      \     "test/*_test.exs": {
      \       "alternate": "web/{}.ex",
      \       "type": "test",
      \     },
      \     "test/controllers/*_test.exs": {
      \       "alternate": "web/controllers/{}.ex",
      \       "skeleton": "phoenix_test_controller",
      \       "type": "test",
      \     },
      \     "test/views/*_test.exs": {
      \       "alternate": "web/views/{}.ex",
      \       "skeleton": "phoenix_test_view",
      \       "type": "test",
      \     },
      \     "test/models/*_test.exs": {
      \       "alternate": "web/models/{}.ex",
      \       "skeleton": "phoenix_test_model",
      \       "type": "test",
      \     },
      \   }
let s:codeception =
      \   {
      \     "tests/unit/*Test.php": {
      \       "alternate": ["app/{}.php", "lib/{}.php"],
      \       "skeleton": "codeception_unit",
      \       "type": "test"
      \     },
      \     "tests/functional/*Cept.php": {
      \       "alternate": ["app/{}.php", "lib/{}.php"],
      \       "skeleton": "codeception_cept",
      \       "type": "test"
      \     },
      \     "tests/functional/*Cest.php": {
      \       "alternate": ["app/{}.php", "lib/{}.php"],
      \       "skeleton": "codeception_cest",
      \       "type": "test"
      \     },
      \     "tests/acceptance/*Cept.php": {
      \       "alternate": ["app/{}.php", "lib/{}.php"],
      \       "skeleton": "codeception_cept",
      \       "type": "test"
      \     },
      \     "tests/acceptance/*Cest.php": {
      \       "alternate": ["app/{}.php", "lib/{}.php"],
      \       "skeleton": "codeception_cest",
      \       "type": "test"
      \     },
      \     "app/*.php": {
      \       "alternate": [
      \         "tests/unit/{}Test.php",
      \         "tests/functional/{}Cest.php",
      \         "tests/functional/{}Cept.php",
      \         "tests/acceptance/{}Cest.php",
      \         "tests/acceptance/{}Cept.php",
      \       ]
      \     },
      \     "lib/*.php": {
      \       "alternate": ["tests/unit/{}Test.php", "tests/functional/{}Cept.php", "tests/functional/{}Cest.php"]
      \     },
      \   }
let g:projectionist_heuristics = {}
let g:projectionist_heuristics["composer.json&app/Mage.php"] = s:magento_module
let g:projectionist_heuristics["composer.json&bin/magento"] = s:magento2_module
let g:projectionist_heuristics["artisan&composer.json"] = s:laravel
let g:projectionist_heuristics["*.ex|*.exs"] = s:elixir
let g:projectionist_heuristics["mix.exs&deps/phoenix/"] = s:phoenixframework
let g:projectionist_heuristics["codeception.yml"] = s:codeception
