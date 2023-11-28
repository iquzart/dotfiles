return {
    {
      'towolf/vim-helm',
      ft = 'helm',
    },
    {
      'neovim/nvim-lspconfig',
      opts = {
        servers = {
          helm = {},
          yamlls = {
            filetypes_exclude = { 'helm' },
          },
        },
      },
      setup = {
        yamlls = function(_, opts)
          local yaml = require('lspconfig.server_configurations.yamlls')
          -- @param ft string
          opts.filetypes = vim.tbl_filter(function(ft)
            return not vim.tbl_contains(opts.filetypes_exclude or {}, ft)
          end, yaml.default_config.filetypes)
        end,
      }
    },
  }
  
  -- The line beneath this is called `modeline`. See `:help modeline`
  -- vim: ts=2 sts=2 sw=2 et