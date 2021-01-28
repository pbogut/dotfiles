local lspconfig = require('lspconfig')
local me = {}

function me.setup(on_attach)
  lspconfig.intelephense.setup {
    on_attach = on_attach,
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
  }
end

return me
