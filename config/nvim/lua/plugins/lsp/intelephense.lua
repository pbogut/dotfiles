local lspconfig = require('lspconfig')
local me = {}

function me.setup(opts)
  opts = vim.tbl_deep_extend('keep', opts, {
    filetypes = {"php", "blade"},
    settings = {
      intelephense = {
        files = {
          associations = {
            "*.php", "*.phtml", "*.blade.php"
          },
        },
        environment = {
          includePaths = {
            os.getenv('PROJECTS') .. '/github.com/deployphp/deployer',
          }
        }
      }
    }
  })
  lspconfig.intelephense.setup(opts)
end

return me
