local M = {}

function M.setup(on_attach)
  require("lazy").setup({
    { "tpope/vim-sensible" },
    { "junegunn/fzf", build = "./install --bin" },
    { "junegunn/fzf.vim" },
    { "dense-analysis/ale" },
    {
      "neovim/nvim-lspconfig",
      config = function()
        local lspconfig = require("lspconfig")
        lspconfig.gopls.setup({ on_attach = on_attach })
        lspconfig.rust_analyzer.setup({ on_attach = on_attach })
        lspconfig.dockerls.setup({ on_attach = on_attach })
      end
    },
    {
      "ekalinin/Dockerfile.vim",
      ft = { "Dockerfile" }
    },
    {
      "stevearc/conform.nvim",
      config = function()
        require("conform").setup({
          format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
          },
          formatters_by_ft = {
            go = { "goimports", "gofmt" },
            rust = { "rustfmt" },
          },
        })
      end
    }
  })
end

return M
