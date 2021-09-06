local u = require('utils')
local h = require('projector.helper')
local cmd = vim.cmd
local bo = vim.bo
local o = vim.o
local l = {}

u.command('Skel', 'lua require"projector".template_from_cmd(<q-args>)', {
  nargs = '?'
})
u.map('n', '<space>ta', ':lua require"projector".go_alternate()<cr>', { silent = true })
u.augroup('x_templates', {
    BufNewFile = {
      {'*', function()
          -- initially ft is not available and ultisnip is not working correctly
          -- so we deffer to next loop when ft is set properly
          vim.schedule(function()
            -- cmd('unsilent lua require"projector".do_template()')
            cmd('lua require"projector".do_template()')
          end)
      end},
    },
    BufNew = {
      {'*', function()
          -- initially ft is not available and ultisnip is not working correctly
          -- so we deffer to next loop when ft is set properly
          vim.schedule(function()
            -- check if fiel is empty, if so then populate from template
            if vim.fn.line('$') == 1 and vim.fn.getline('$') == '' then
              require('projector').do_template()
            end
          end)
      end},
    },
})

function l.mag_rm_pool(text)
  return text:gsub('^[a-z]*/(.*)', '%1') -- drop first part which is code pool
end

function l.mag_add_block(text)
  return text:gsub('^(.*)/(.*)/(.*)$', '%1/%2/Block/%3')
end

-- config for projector module
return {
  --magento project
  ["composer.json&app/Mage.php"] = {
    priority = 100,
    patterns = {
      ['app/code/(.*)/Block/(.*)%.php'] = {
        priority = 100,
        template = "_magento_block",
        alternate = function(_, opt)
          local path = h.snakecase(l.mag_rm_pool(opt.match[1]))
          local file = h.snakecase(opt.match[2])
          return {'app/design/frontend/base/default/template/'
                  .. path .. '/' .. file .. '.phtml'}
        end
      },
      ['app/code/**/Helper/*.php'] = {
        priority = 100,
        template = "_magento_helper",
      },
      ['app/code/**/Model/Resource/*/Collection.php'] = {
        priority = 100,
        template = "_magento_collection",
      },
      ['app/code/**/Model/Resource/*.php'] = {
        priority = 100,
        template = "_magento_resource",
      },
      ['app/code/**/Model/*.php'] = {
        priority = 100,
        template = "_magento_model",
      },
      ['app/design/frontend/base/default/template/(.*)%.phtml'] = {
        priority = 100,
        alternate = function(_, opt)
          local filename =
            l.mag_add_block(h.capitalize(h.camelcase(opt.match[1])))
          return {
            'app/code/core/' .. filename .. '.php',
            'app/code/community/' .. filename .. '.php',
            'app/code/local/' .. filename .. '.php',
          }
        end
      }
    }
  },
  -- magento2 project
  ["composer.json&bin/magento"] = {
    generators = {
      module = {
        variables = {
          Vendor = '',
          ModuleName = '',
        },
        {
          'app/code/{Vendor}/{ModuleName}/registration.php',
          'app/code/{Vendor}/{ModuleName}/etc/module.xml',
        }
      }
    },
    priority = 100,
    patterns = {
      ['app/code/(.*)/Block/(.*)%.php'] = {
        priority = 100,
        template = "magento2/block.php",
        alternate = function(_, opt)
          return {
            'app/code/' .. opt.match[1] .. '/view/frontend/templates/'
              .. h.snakecase(opt.match[2]) .. '.phtml',
          }
        end,
      },
      ['app/code/(.*)/view/frontend/templates/(.*)%.phtml'] = {
        priority = 100,
        template = "magento2/block.phtml",
        alternate = function(_, opt)
          return {
            'app/code/' .. opt.match[1] .. '/Block/'
              ..  h.capitalize(h.camelcase(opt.match[2])) .. '.php',
          }
        end,
      },
      ['app/code/.*/Model/ResourceModel/.*/Collection%.php'] = {
        template = "_magento2_resource_model_collection",
        priority = 100
      },
      ['app/code/.*/Model/ResourceModel/.*/CollectionFactory%.php'] = {
        template = "_magento2_resource_model_collection_factory",
        priority = 100
      },
      ['app/code/.*/Model/ResourceModel/.*/DataProvider%.php'] = {
        template = "_magento2_resource_model_data_provider",
        priority = 100
      },
      ['app/code/.*/Model/ResourceModel/.*%.php'] = {
        template = "_magento2_resource_model_entity",
        priority = 200
      },
      ['app/code/.*/Model/Source/.*%.php'] = {
        template = "_magento2_resource_model_source",
        priority = 100
      },
      ['app/code/.*/Helper/.*%.php'] = {
        template = "_magento2_helper",
        priority = 100
      },
      ['app/code/.*/Model/.*%.php'] = {
        template = "_magento2_model_entity",
        priority = 300
      },
      ['app/code/.*/view/adminhtml/layout/.*_index.xml'] = {
        template = "_magento2_layout_entity_index"
      },
      ['app/code/.*/view/adminhtml/layout/.*_new.xml'] = {
        template = "_magento2_layout_entity_new"
      },
      ['app/code/.*/view/adminhtml/layout/.*_edit.xml'] = {
        template = "_magento2_layout_entity_edit"
      },
      ['app/code/.*/etc/email_templates.xml'] = {
        template = "magento2/etc/email_templates.xml"
      },
      ['app/code/.*/view/adminhtml/ui_component/.*_listing.xml'] = {
        template = "_magento2_layout_ui_component_listing"
      },
      ['app/code/.*/view/adminhtml/ui_component/.*_form.xml'] = {
        template = "_magento2_layout_ui_component_form"
      },
      ['app/code/.*/Controller/Adminhtml/.*/Index%.php'] = {
        template = "_magento2_adminhtml_controller_index",
        priority = 100
      },
      ['app/code/.*/Controller/Adminhtml/.*/Edit%.php'] = {
        template = "_magento2_adminhtml_controller_edit",
        priority = 100
      },
      ['app/code/.*/Controller/Adminhtml/.*/NewAction%.php'] = {
        template = "_magento2_adminhtml_controller_new",
        priority = 100
      },
      ['app/code/.*/Controller/Adminhtml/.*/Save%.php'] = {
        template = "_magento2_adminhtml_controller_save",
        priority = 100
      },
      ['app/code/.*/Controller/Adminhtml/.*%.php'] = {
        template = "_magento2_adminhtml_controller",
        priority = 500
      },
      ['app/code/.*/Controller/.*%.php'] = {
        template = "_magento2_controller",
        priority = 200
      },
      ['app/code/.*/Observer/.*%.php'] = {
        template = "_magento2_observer",
        priority = 100
      },
      ['app/code/.*/Source/.*%.php'] = {
        template = "/magento2/Source/Source.php",
        priority = 100,
      },
      ['app/code/.*/etc/widget.xml'] = {
        template = "/magento2/etc/widget.xml",
        priority = 100,
      },
      ['app/code/.*/etc/module.xml'] = {
        template = "_magento2_module",
        priority = 100,
      },
      ['app/code/.*/etc/.*/?events.xml'] = {
        template = "_magento2_events",
        priority = 100,
      },
      ['app/code/.*/etc/frontend/routes.xml'] = {
        template = "_magento2_frontend_routes",
        priority = 100,
      },
      ['app/code/.*/etc/adminhtml/routes.xml'] = {
        template = "_magento2_adminhtml_routes",
        priority = 100,
      },
      ['app/code/.*/etc/.*/?di.xml'] = {
        template = "_magento2_di",
        priority = 100,
      },
      ['app/code/.*/registration.php'] = {
        template = "magento2/registration.php",
        priority = 100,
      },
      ['.*%.php'] = {
        template = "_magento2_class",
        priority = 1000,
      },
      ['.*/web/templates?/.*/[^/]*%.html$'] = {
        alternate = function(relative, _)
          local glob = relative:gsub('(.*)/web/templates?/.*/(.-)%.html', '%1/web/%*%*/%2.js')
          return u.glob(glob)
        end
      },
      ['.*/web/js/.*/[^/]*%.js$'] = {
        alternate = function(relative, _)
          local glob = relative:gsub('(.*)/web/js/.*/(.-)%.js', '%1/web/%*%*/%2.html')
          return u.glob(glob)
        end
      },
    }
  },
  -- laravel project
  ["artisan&composer.json"] = {
    project_init = function()
      u.augroup('x_laravel', {
        FileType = {'php', function()
          -- copied from polyglot/blade so it works in controllers as well
          bo.suffixesadd = '.blade.php,.php'
          bo.includeexpr = [[substitute(v:fname,'\.','/','g')]]
          bo.path = o.path .. [[,resources/views;]]
        end}
      })
    end,
    priority = 100,
    patterns = {
      ['app/(.*)%.php'] = {
        alternate = {
          "tests/Unit/%1Test.php",
          "tests/Feature/%1Test.php"
        },
        template = "_laravel_class",
        priority = 1000,
      },
      ['app/Http/Controllers/.*Controller%.php'] = {
        template = "_laravel_controller",
        priority = 100,
      },
      ['tests/Unit/(.*)Test%.php'] = {
        alternate = "app/%1.php",
        template = "_laravel_test",
        priority = 100,
      },
      ['tests/Feature/(.*)Test.php'] = {
        alternate = "app/%1.php",
        template = "_laravel_test",
        priority = 100,
      },
      ['app/Console/Commands/.*%.php'] = {
        template = "_laravel_command",
        priority = 100,
      },
    }
  },
  -- codeception subproject
  ["codeception.yml"] = {
    priority = 500,
    patterns = {
      ['tests/unit/(.*)Test%.php'] = {
        alternate = {"app/%1.php", "lib/%1.php"},
        skeleton = "_codeception_unit",
      },
      ['tests/functional/(.*)Cept%.php'] = {
        alternate = {"app/%1.php", "lib/%1.php"},
        skeleton = "_codeception_cept",
      },
      ['tests/functional/(.*)Cest%.php'] = {
        alternate = {"app/%1.php", "lib/%1.php"},
        skeleton = "_codeception_cest",
      },
      ['tests/acceptance/(.*)Cept%.php'] = {
        alternate = {"app/%1.php", "lib/%1.php"},
        skeleton = "_codeception_cept",
      },
      ['tests/acceptance/(.*)Cest.php'] = {
        alternate = {"app/%1.php", "lib/%1.php"},
        skeleton = "_codeception_cest",
      },
      ['^app/(.*)%.php'] = {
        alternate = {
          "tests/unit/%1Test.php",
          "tests/functional/%1Cest.php",
          "tests/functional/%1Cept.php",
          "tests/acceptance/%1Cest.php",
          "tests/acceptance/%1Cept.php",
        }
      },
      ['^lib/(.*)%.php'] = {
        alternate = {
          "tests/unit/%1Test.php",
          "tests/functional/%1Cept.php",
          "tests/functional/%1Cest.php",
        }
      },
    }
  },
  -- elixir phoenix
  ["mix.exs&deps/phoenix/"] = {
    priority = 100,
    patterns = {
      ['(.*)%.exs'] = {
        template = "_phoenix_skel",
        priority = 300,
      },
      ['(.*)%.ex'] = {
        template = "_phoenix_skel",
        priority = 300,
      },
      ['(.*)_view%.ex'] = {
        template = "_phoenix_view",
        priority = 100,
      },
      ['^lib/(.*)%.ex'] = {
        alternate = "test/%1_test.exs",
        priority = 200,
      },
      ['^web/(.*)%.ex'] = {
        alternate = "test/%1_test.exs",
        priority = 200,
      },
      ['^test/(.*)_test%.exs'] = {
        alternate = "web/%1.ex",
        priority = 200,
      },
      ['^test/controllers/(.*)_test%.exs'] = {
        alternate = "web/controllers/%1.ex",
        template = "_phoenix_test_controller",
        priority = 100,
      },
      ['^test/views/(.*)_test%.exs'] = {
        alternate = "web/views/%1.ex",
        template = "_phoenix_test_view",
        priority = 100,
      },
      ['^test/models/(.*)_test%.exs'] = {
        alternate = "web/models/%1.ex",
        template = "_phoenix_test_model",
        priority = 100,
      },
    }
  },
  -- elixir
  ["mix.exs"] = {
    priority = 500,
    patterns = {
      ['lib/(.*)%.ex'] = {
        alternate = "test/%1_test.exs",
        priority = 300,
      },
      ['test/(.*)_test%.exs'] = {
        alternate = "lib/%1.ex",
        template = "_test",
        priority = 300,
      },
      ['(.*)%.exs'] = {
        alternate = "%1_test.exs",
        priority = 500,
      },
      ['(.*]%.ex'] = {
        alternate = "%1_test.exs",
        priority = 500,
      },
      ['(.*)_test%.exs'] = {
        alternate = {"%1.exs", "%1.ex"},
        template = "_test",
        priority = 400,
      },
    }
  },
  -- polybar scripts
  ['.polybar'] = {
    priority = 100,
    patterns = {
      ['*.zsh'] = {
        skeleton = "polybar_script"
      },
    }
  },
  -- match anything
  ['*'] = {
    priority = 5000,
    patterns = {
      ['.*%.php'] = {
        template = "file.php",
        priority = 5000,
      },
      ['docker%-compose%.yml'] = {
        template = "docker-compose.yml",
        priority = 5000,
      },
      ['.*'] = {
        template = "_skel",
        priority = 5000,
      },
    }
  }
}
