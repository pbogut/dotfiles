return {
  'projector',
  dir = vim.fn.stdpath('config') .. '/local/projector',
  config = function()
    local command = vim.api.nvim_create_user_command
    local projector = require('projector')
    local h = require('projector.helper')
    local u = require('pbogut.utils')
    local k = vim.keymap
    local bo = vim.bo
    local o = vim.o
    local l = {}

    command('Skel', 'lua require"projector".template_command(<q-args>)', {
      nargs = '?',
      complete = 'customlist,v:lua.projector.temp_completion',
    })

    command('Gen', 'lua require"projector".generate(<q-args>)', {
      nargs = '?',
      complete = 'customlist,v:lua.projector.gen_completion',
    })

    k.set('n', '<space>ta', '<cmd>lua require"projector".go_alternate()<cr>', { silent = true })

    vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufNew' }, {
      group = vim.api.nvim_create_augroup('x_templates', { clear = true }),
      pattern = '*',
      callback = function()
        -- initially ft is not available and ultisnip is not working correctly
        -- so we deffer to next loop when ft is set properly
        vim.schedule(function()
          if vim.fn.line('$') == 1 and vim.fn.getline('$') == '' then
            require('projector').do_template()
          end
        end)
      end,
    })

    function l.mag_rm_pool(text)
      return text:gsub('^[a-z]*/(.*)', '%1') -- drop first part which is code pool
    end

    function l.mag_add_block(text)
      return text:gsub('^(.*)/(.*)/(.*)$', '%1/%2/Block/%3')
    end

    -- config for projector module
    projector.setup({
      templates = {
        engine = 'luasnip',
        path = os.getenv('HOME') .. '/.config/nvim/templates',
      },
      projections = {
        -- zola... maybe
        ['themes&templates&content&config.toml'] = {
          priority = 100,
          luasnip = {
            paths = {
              vim.fn.stdpath('config') .. '/snippets/zola',
            },
          },
        },
        ['autoexec.cfg&cs2-autoexec.cfg&link.sh'] = {
          project_init = {
            function()
              vim.api.nvim_create_autocmd('BufWritePost', {
                group = vim.api.nvim_create_augroup('x_csgo', { clear = true }),
                pattern = '*.cfg',
                callback = function()
                  vim.cmd.Action('link')
                end,
              })
            end,
          },
        },
        --magento project
        ['composer.json&app/Mage.php'] = {
          priority = 100,
          luasnip = {
            paths = {
              vim.fn.stdpath('config') .. '/snippets/magento',
            },
          },
          snippy = {
            scopes = {
              php = { 'magento/php' },
              xml = { 'magento/xml' },
            },
          },
          patterns = {
            ['app/code/(.*)/Block/(.*)%.php'] = {
              priority = 100,
              template = 'magento/Block',
              alternate = function(_, opt)
                local path = h.snakecase(l.mag_rm_pool(opt.match[1]))
                local file = h.snakecase(opt.match[2])
                return {
                  'app/design/frontend/base/default/template/' .. path .. '/' .. file .. '.phtml',
                }
              end,
            },
            ['app/code/**/Helper/*.php'] = {
              priority = 100,
              template = 'magento/Helper',
            },
            ['app/code/**/Model/Resource/*/Collection.php'] = {
              priority = 100,
              template = 'magento/Collection',
            },
            ['app/code/**/Model/Resource/*.php'] = {
              priority = 100,
              template = 'magento/Resource',
            },
            ['app/code/**/Model/*.php'] = {
              priority = 100,
              template = 'magento/Model',
            },
            ['app/design/frontend/base/default/template/(.*)%.phtml'] = {
              priority = 100,
              alternate = function(_, opt)
                local filename = l.mag_add_block(h.capitalize(h.camelcase(opt.match[1])))
                return {
                  'app/code/core/' .. filename .. '.php',
                  'app/code/community/' .. filename .. '.php',
                  'app/code/local/' .. filename .. '.php',
                }
              end,
            },
            ['.*%.php'] = {
              template = 'magento/Class',
              priority = 4500,
            },
          },
        },
        -- magento2 project
        ['composer.json&bin/magento&mage-docker'] = {
          priority = 50,
          project_init = {
            function()
              vim.api.nvim_create_user_command('Mage', function(opts)
                local cmd = './mage-docker ' .. opts.args
                if not opts.bang then
                  vim.cmd([[rightbelow 20split]])
                  vim.cmd.term(cmd)
                  vim.cmd.startinsert()
                else
                  vim.fn.jobstart(cmd)
                end
              end, { nargs = '*', bang = true })

              vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup('x_magento2', { clear = true }),
                pattern = 'xml',
                callback = function()
                  -- let to use gf on FQN in xml files (at least for local modules)
                  bo.suffixesadd = '.php'
                  bo.includeexpr = [[substitute(v:fname,'\\','/','g')]]
                  bo.path = o.path .. [[,app/code;]]
                  o.isfname = '@,48-57,/,.,-,_,+,,,#,$,%,~,=,\\'
                end,
              })
            end,
          },
        },

        ['composer.json&bin/magento'] = {
          priority = 100,
          luasnip = {
            paths = {
              vim.fn.stdpath('config') .. '/snippets/magento2',
              vim.fn.stdpath('config') .. '/snippets/knockout',
            },
          },
          snippy = {
            scopes = {
              php = { 'magento2/php' },
              xml = { 'magento2/xml' },
              html = { 'knockout/html' },
              phtml = { 'knockout/html' },
            },
          },
          project_init = {
            function()
              vim.api.nvim_create_user_command('Mage', function(opts)
                --[[ vim.cmd.split() ]]
                local cmd = 'bin/magento ' .. opts.args
                if not opts.bang then
                  vim.cmd([[rightbelow 20split]])
                  vim.cmd.term(cmd)
                  vim.cmd.startinsert()
                else
                  vim.fn.jobstart(cmd)
                end
              end, { nargs = '*', bang = true })
            end,
          },
          generators = {
            module = {
              variables = {
                { name = 'Vendor', prompt = 'Vendor name' },
                { name = 'ModuleName', prompt = 'Module name' },
              },
              new = {
                {
                  file = 'app/code/{Vendor}/{ModuleName}/registration.php',
                  template = 'magento2/registration.php',
                },
                {
                  file = 'app/code/{Vendor}/{ModuleName}/etc/module.xml',
                  template = 'magento2/etc/module.xml',
                },
              },
            },
          },
          patterns = {
            ['app/code/(.*)/Plugin/(.*)%.php'] = {
              priority = 100,
              template = 'magento2/Plugin',
            },
            ['app/code/(.*)/Block/(.*)%.php'] = {
              priority = 100,
              template = 'magento2/Block',
              alternate = function(_, opt)
                return {
                  'app/code/' .. opt.match[1] .. '/view/frontend/templates/' .. h.snakecase(opt.match[2]) .. '.phtml',
                }
              end,
            },
            ['app/code/(.*)/view/frontend/templates/(.*)%.phtml'] = {
              priority = 100,
              template = 'magento2/block.phtml',
              alternate = function(_, opt)
                return {
                  'app/code/' .. opt.match[1] .. '/Block/' .. h.capitalize(h.camelcase(opt.match[2])) .. '.php',
                }
              end,
            },
            ['app/code/.*/Model/ResourceModel/.*/Collection%.php'] = {
              template = 'magento2/Collection',
              priority = 100,
            },
            ['app/code/.*/Console/.*%.php'] = {
              template = 'magento2/Console',
              priority = 100,
            },
            ['app/code/.*/Model/ResourceModel/.*/CollectionFactory%.php'] = {
              template = 'magento2/CollectionFactory',
              priority = 100,
            },
            ['app/code/.*/Model/ResourceModel/.*/DataProvider%.php'] = {
              template = 'magento2/DataProvider',
              priority = 100,
            },
            ['app/code/.*/Model/ResourceModel/.*%.php'] = {
              template = 'magento2/ResourceModel',
              priority = 200,
            },
            ['app/code/.*/Helper/.*%.php'] = {
              template = 'magento2/Helper',
              priority = 100,
            },
            ['app/code/.*/Model/.*%.php'] = {
              template = 'magento2/Model',
              priority = 300,
            },
            ['app/code/.*/view/adminhtml/layout/.*_index.xml'] = {
              template = 'magento2/view/adminhtml/layout/layout_entity_index.xml',
            },
            ['app/code/.*/view/adminhtml/layout/.*_new.xml'] = {
              template = 'magento2/view/adminhtml/layout/layout_entity_new.xml',
            },
            ['app/code/.*/view/adminhtml/layout/.*_edit.xml'] = {
              template = 'magento2/view/adminhtml/layout/layout_entity_edit.xml',
            },
            ['app/code/.*/etc/email_templates.xml'] = {
              template = 'magento2/etc/email_templates.xml',
            },
            ['app/code/.*/view/adminhtml/ui_component/.*_listing.xml'] = {
              template = 'magento2/view/adminhtml/ui_component/entity_listing.xml',
            },
            ['app/code/.*/view/adminhtml/ui_component/.*_form.xml'] = {
              template = 'magento2/view/adminhtml/ui_component/entity_form.xml',
            },
            ['app/code/.*/Controller/Adminhtml/.*/Index%.php'] = {
              template = 'magento2/Controller/Adminhtml/Index',
              priority = 100,
            },
            ['app/code/.*/Controller/Adminhtml/.*/Edit%.php'] = {
              template = 'magento2/Controller/Adminhtml/Edit',
              priority = 100,
            },
            ['app/code/.*/Controller/Adminhtml/.*/NewAction%.php'] = {
              template = 'magento2/Controller/Adminhtml/NewAction',
              priority = 100,
            },
            ['app/code/.*/Controller/Adminhtml/.*/Save%.php'] = {
              template = 'magento2/Controller/Adminhtml/Save',
              priority = 100,
            },
            ['app/code/.*/Controller/Adminhtml/.*%.php'] = {
              template = 'magento2/Controller/Adminhtml/Action',
              priority = 500,
            },
            ['app/code/.*/Controller/.*%.php'] = {
              template = 'magento2/Controller/Action',
              priority = 200,
            },
            ['app/code/.*/Observer/.*%.php'] = {
              template = 'magento2/Observer',
              priority = 100,
            },
            ['app/code/.*/Source/.*%.php'] = {
              template = '/magento2/Source',
              priority = 100,
            },
            ['app/code/.*/Model/Source/.*%.php'] = {
              template = 'magento2/Source',
              priority = 100,
            },
            ['app/code/.*/etc/widget.xml'] = {
              template = '/magento2/etc/widget.xml',
              priority = 100,
            },
            ['app/code/.*/etc/module.xml'] = {
              template = 'magento2/etc/module.xml',
              priority = 100,
            },
            ['app/code/.*/etc/.*/?events.xml'] = {
              template = 'magento2/etc/events.xml',
              priority = 100,
            },
            ['app/code/.*/etc/.*/routes.xml'] = {
              template = 'magento2/etc/routes.xml',
              priority = 100,
            },
            ['app/code/.*/etc/.*/?di.xml'] = {
              template = 'magento2/etc/di.xml',
              priority = 100,
            },
            ['app/code/.*/registration.php'] = {
              template = 'magento2/registration.php',
              priority = 100,
            },
            ['app/code/([^/]+/[^/]+)/(.*)%.php'] = {
              priority = 3000,
              alternate = function(_, opt)
                return {
                  'app/code/' .. opt.match[1] .. '/Test/' .. opt.match[2] .. 'Test.php',
                }
              end,
            },
            ['.*%.php'] = {
              template = 'php/Class',
              priority = 4500,
            },
            ['.*/web/templates?/.*/[^/]*%.html$'] = {
              alternate = function(relative, _)
                local glob = relative:gsub('(.*)/web/templates?/.*/(.-)%.html', '%1/web/%*%*/%2.js')
                return u.glob(glob)
              end,
            },
            ['.*/web/js/.*/[^/]*%.js$'] = {
              alternate = function(relative, _)
                local glob = relative:gsub('(.*)/web/js/.*/(.-)%.js', '%1/web/%*%*/%2.html')
                return u.glob(glob)
              end,
            },
          },
        },
        -- laravel project
        ['artisan&composer.json'] = {
          priority = 100,
          project_init = {
            function()
              vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup('x_laravel', { clear = true }),
                pattern = 'php',
                callback = function()
                  -- copied from polyglot/blade so it works in controllers as well
                  bo.suffixesadd = '.blade.php,.php'
                  bo.includeexpr = [[substitute(v:fname,'\.','/','g')]]
                  bo.path = o.path .. [[,resources/views;]]
                end,
              })
            end,
          },
          luasnip = {
            paths = {
              vim.fn.stdpath('config') .. '/snippets/laravel',
            },
          },
          snippy = {
            scopes = {
              php = { 'laravel/php' },
            },
          },
          patterns = {
            ['app/(.*)%.php'] = {
              alternate = {
                'tests/Unit/%1Test.php',
                'tests/Feature/%1Test.php',
              },
              template = 'php/Class',
              priority = 4500,
            },
            ['app/Http/Controllers/.*Controller%.php'] = {
              template = 'laravel/Controller',
              priority = 100,
            },
            ['tests/Unit/(.*)Test%.php'] = {
              alternate = 'app/%1.php',
              template = 'laravel/Test',
              priority = 100,
            },
            ['tests/Feature/(.*)Test.php'] = {
              alternate = 'app/%1.php',
              template = 'laravel/Test',
              priority = 100,
            },
            ['app/Models/.*%.php'] = {
              template = 'laravel/Model',
              priority = 100,
            },
            ['app/Console/Commands/.*%.php'] = {
              template = 'laravel/Command',
              priority = 100,
            },
          },
        },
        -- codeception subproject
        ['codeception.yml'] = {
          priority = 500,
          patterns = {
            ['tests/unit/(.*)Test%.php'] = {
              alternate = { 'app/%1.php', 'lib/%1.php' },
              skeleton = '_codeception_unit',
            },
            ['tests/functional/(.*)Cept%.php'] = {
              alternate = { 'app/%1.php', 'lib/%1.php' },
              skeleton = '_codeception_cept',
            },
            ['tests/functional/(.*)Cest%.php'] = {
              alternate = { 'app/%1.php', 'lib/%1.php' },
              skeleton = '_codeception_cest',
            },
            ['tests/acceptance/(.*)Cept%.php'] = {
              alternate = { 'app/%1.php', 'lib/%1.php' },
              skeleton = '_codeception_cept',
            },
            ['tests/acceptance/(.*)Cest.php'] = {
              alternate = { 'app/%1.php', 'lib/%1.php' },
              skeleton = '_codeception_cest',
            },
            ['^app/(.*)%.php'] = {
              alternate = {
                'tests/unit/%1Test.php',
                'tests/functional/%1Cest.php',
                'tests/functional/%1Cept.php',
                'tests/acceptance/%1Cest.php',
                'tests/acceptance/%1Cept.php',
              },
            },
            ['^lib/(.*)%.php'] = {
              alternate = {
                'tests/unit/%1Test.php',
                'tests/functional/%1Cept.php',
                'tests/functional/%1Cest.php',
              },
            },
          },
        },
        -- elixir phoenix
        ['mix.exs&deps/phoenix/'] = {
          priority = 100,
          generators = {
            tailwind = {
              cmd = {
                'cd assets',
                'npm install autoprefixer postcss postcss-import tailwindcss --save-dev',
                'cd ..',
              },
              new = {
                {
                  file = 'assets/postcss.config.js',
                  template = 'js/postcss.config.js',
                },
                {
                  file = 'assets/tailwind.config.js',
                  template = 'elixir/tailwind.config.js',
                },
              },
              update = {
                {
                  file = 'config/dev.exs',
                  after = 'watchers: %[',
                  insert = {
                    '    npx: [',
                    '      "tailwindcss",',
                    '      "--input=css/app.css",',
                    '      "--output=../priv/static/assets/app.css",',
                    '      "--postcss",',
                    '      "--watch",',
                    '      cd: Path.expand("../assets", __DIR__)',
                    '    ],',
                  },
                },
                {
                  file = 'assets/css/app.css',
                  prepend = {
                    '@import "tailwindcss/base";',
                    '@import "tailwindcss/components";',
                    '@import "tailwindcss/utilities";',
                    '/*',
                    '@layer components {',
                    '  // custom components',
                    '}',
                    '*/',
                    '',
                  },
                },
                {
                  file = 'assets/js/app.js',
                  replace = '^import "%.%./css/app.css"',
                  with = '// import "../css/app.css"',
                },
              },
            },
            alpinejs = {
              cmd = {
                'cd assets',
                'npm install alpinejs',
                'cd ..',
              },
              update = {
                {
                  file = 'assets/js/app.js',
                  replace = 'let liveSocket %= new LiveSocket%("%/live", Socket, %{(params:.-)%}%)$',
                  with = {
                    'let liveSocket %= new LiveSocket%("%/live", Socket, %{',
                    '  %1',
                    '%}%)',
                  },
                },
                {
                  file = 'assets/js/app.js',
                  prepend = {
                    'import Alpine from "alpinejs";',
                    '',
                    'window.Alpine = Alpine;',
                    'Alpine.start();',
                  },
                  after = 'let liveSocket %= new LiveSocket%("%/live", Socket, %{',
                  insert = {
                    '  dom: {',
                    '    onBeforeElUpdated(from, to) {',
                    '      if (from._x_dataStack) {',
                    '        window.Alpine.clone(from, to);',
                    '      }',
                    '    },',
                    '  },',
                  },
                },
              },
            },
            static_assets = {
              cmd = {
                'chmod +x lib/mix/tasks/run_command.sh',
              },
              new = {
                {
                  file = 'lib/mix/tasks/static_assets.ex',
                  template = 'elixir/static_assets/static_assets.ex',
                },
                {
                  file = 'lib/mix/tasks/run_command.sh',
                  template = 'elixir/static_assets/run_command.sh',
                },
              },
              update = {
                {
                  file = 'config/dev.exs',
                  after = 'watchers: %[',
                  insert = {
                    '    static: {Mix.Tasks.StaticAssets, :run, [~w(--watch --purge)]},',
                  },
                },
                {
                  file = 'mix.exs',
                  replace = '"assets.deploy": %[(.-)%]',
                  with = '"assets.deploy": %["static_assets --purge", %1%]',
                },
              },
            },
          },
          patterns = {
            ['(.*)%.exs'] = {
              template = 'elixir/module',
              priority = 300,
            },
            ['(.*)%.ex'] = {
              template = 'elixir/module',
              priority = 300,
            },
            ['(.*)_view%.ex'] = {
              template = 'elixir/view',
              priority = 100,
            },
            ['^lib/(.*)%.ex'] = {
              alternate = 'test/%1_test.exs',
              priority = 200,
            },
            ['^web/(.*)%.ex'] = {
              alternate = 'test/%1_test.exs',
              priority = 200,
            },
            ['^test/(.*)_test%.exs'] = {
              alternate = { 'lib/%1.ex', 'web/%1.ex' },
              template = 'elixir/data_test',
              priority = 200,
            },
            ['^test/controllers/(.*)_test%.exs'] = {
              alternate = 'web/controllers/%1.ex',
              template = 'elixir/controller_test',
              priority = 100,
            },
            ['^test/channels/(.*)_test%.exs'] = {
              alternate = 'web/channels/%1.ex',
              template = 'elixir/channel_test',
              priority = 100,
            },
            ['^test/views/(.*)_test%.exs'] = {
              alternate = 'web/views/%1.ex',
              template = 'elixir/view_test',
              priority = 100,
            },
            ['^test/(.*)/features/(.*)_test%.exs'] = {
              template = 'elixir/wallaby/feature_test',
              priority = 100,
            },
            ['tailwind%.config%.js'] = {
              template = 'elixir/tailwind.config.js',
              priority = 100,
            },
          },
        },
        -- elixir
        ['mix.exs'] = {
          priority = 500,
          patterns = {
            ['lib/(.*)%.ex'] = {
              alternate = 'test/%1_test.exs',
              template = 'elixir/module',
              priority = 300,
            },
            ['test/(.*)_test%.exs'] = {
              alternate = 'lib/%1.ex',
              template = 'elixir/unit',
              priority = 300,
            },
            ['(.*)%.exs'] = {
              alternate = '%1_test.exs',
              template = 'elixir/module',
              priority = 500,
            },
            ['(.*]%.ex'] = {
              alternate = '%1_test.exs',
              template = 'elixir/module',
              priority = 500,
            },
            ['(.*)_test%.exs'] = {
              alternate = { '%1.exs', '%1.ex' },
              template = 'elixir/unit',
              priority = 400,
            },
          },
        },
        -- polybar scripts
        ['.polybar'] = {
          priority = 100,
          patterns = {
            ['*.zsh'] = {
              skeleton = 'polybar/script',
            },
          },
        },
        -- phpcs
        ['phpcs.xml'] = {
          priority = 1000,
          -- luasnip = {
          --   paths = {
          --     vim.fn.stdpath('config') .. '/snippets/phpcs',
          --   }
          -- },
          snippy = {
            scopes = {
              php = { 'phpcs/php' },
            },
          },
        },
        -- godot
        ['project.godot'] = {
          project_init = {
            function()
              vim.fn.jobstart({ 'bash', '-c', 'sha1sum <<< "' .. vim.fn.getcwd() .. '" |' .. "awk '{print $1}'" }, {
                stdout_buffered = true,
                stderr_buffered = true,
                on_stdout = function(_, out)
                  local hash = out[1]
                  local file = '/tmp/nvim_godot/' .. hash
                  write_to_file(file, vim.v.servername)
                end,
              })
              vim.fn.jobstart({ 'rtx', 'x', '--', 'godot', 'project.godot' })
            end,
          },
        },
        -- match anything
        ['*'] = {
          priority = 5000,
          snippy = {
            scopes = {
              zsh = { 'sh' },
            },
          },
          patterns = {
            ['.*%.php'] = {
              template = 'file.php',
              priority = 5000,
            },
            ['.*%.sh'] = {
              template = 'file.sh',
              priority = 5000,
            },
            ['.*%.zsh'] = {
              template = 'file.zsh',
              priority = 5000,
            },
            ['docker%-compose%.yml'] = {
              template = 'docker-compose.yml',
              priority = 5000,
            },
            ['phpmd%.xml'] = {
              template = 'phpmd.xml',
              priority = 5000,
            },
            ['phpcs%.xml'] = {
              template = 'phpcs.xml',
              priority = 5000,
            },
            ['tailwind%.config%.js'] = {
              template = 'js/tailwind.config.js',
              priority = 5000,
            },
            ['postcss%.config%.js'] = {
              template = 'js/postcss.config.js',
              priority = 5000,
            },
            -- ['.*'] = {
            --   template = "_skel",
            --   priority = 5000,
            -- },
          },
        },
      },
    })
  end,
}
