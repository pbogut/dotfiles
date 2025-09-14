local opts = {
  settings = {
    tailwindCSS = {
      experimental = {
        classRegex = {
          [[class:\s\"([^"]+)\"]],
          [[cls:\s\"([^"]+)\"]],
          [[[a-z]+_class=\"([^"]+)\"]],
        },
      },
      includeLanguages = {
        plaintext = 'html',
        elixir = 'phoenix-heex',
        eelixir = 'html-eex',
        heex = 'phoenix-heex',
        surface = 'phoenix-heex',
        svelte = 'html',
        eruby = 'erb',
        rust = 'html',
        templ = 'html',
      },
    },
  },
}

return opts
