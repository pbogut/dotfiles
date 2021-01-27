local lspconfig = require('lspconfig')
local me = {}

-- # Instalation --
-- ```
-- git cl Microsoft/python-language-server
-- cd src/LanguageServer/Impl
-- dotnet build
-- ```

function me.setup(on_attach)
  lspconfig.pyls_ms.setup {
    on_attach = on_attach,
    cmd = { "dotnet", "exec", os.getenv('HOME') .. "/Projects/github.com/microsoft/python-language-server/output/bin/Debug/Microsoft.Python.LanguageServer.dll" };
  }
end

return me
