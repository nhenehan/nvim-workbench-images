return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- Off by default in LazyVim; jdtls's implementations/references lenses and
      -- rust-analyzer's Run/Debug lenses are worth the cost.
      codelens = { enabled = true },
      inlay_hints = { enabled = true },
      diagnostics = {
        virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
        severity_sort = true,
      },
    },
  },
}
