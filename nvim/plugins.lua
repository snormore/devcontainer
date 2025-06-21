return require("lazy").setup({
    { "tpope/vim-sensible" },
    { "junegunn/fzf.vim" },
    { "dense-analysis/ale" },
    { "neovim/nvim-lspconfig", config = function()
        require("lspconfig").gopls.setup({})
      end
    }
  })
