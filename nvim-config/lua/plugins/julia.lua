-- julials comes from the lang.julia extra. Two things it does not handle:
--   1. Mason ships a `julia-lsp` package whose CLI contract is
--      `julia-lsp <julia_env_path>` -- it takes the project env as a positional arg,
--      which lspconfig's julials cmd does not supply. Exclude it so Mason does not
--      hijack the server.
--   2. LanguageServer.jl lives in ~/.julia/environments/nvim-lspconfig (installed
--      separately); the native `julia -e` cmd is what finds it.
-- Only applies when the julia extra is enabled for this image (NVIM_LANGS).
local langs = vim.env.NVIM_LANGS or "rust,clangd,cmake,java,julia,python"
if not langs:find("julia", 1, true) then
  return {}
end

return {
  {
    "mason-org/mason-lspconfig.nvim",
    optional = true,
    opts = function(_, opts)
      opts.automatic_enable = opts.automatic_enable or {}
      opts.automatic_enable.exclude =
        vim.list_extend(opts.automatic_enable.exclude or {}, { "julials" })
      return opts
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        julials = {
          mason = false,
          settings = {
            julia = {
              completionmode = "qualify",
              lint = {
                missingrefs = "none",
                call = true,
                iter = true,
                lazy = true,
                modname = true,
                pirates = false,
                useoffuncargs = true,
                nothingcomp = true,
              },
              format = { indent = 4, margin = 92 },
            },
          },
        },
      },
    },
  },

  -- REPL-driven workflow. This is the primary Julia debugging story -- see the note
  -- on DAP below.
  {
    "jpalardy/vim-slime",
    ft = { "julia", "python" },
    init = function()
      vim.g.slime_target = "neovim"
      vim.g.slime_no_mappings = 1
      vim.g.slime_bracketed_paste = 1
      vim.g.slime_cell_delimiter = "^\\s*##"
    end,
    keys = {
      { "<leader>jr", "<Plug>SlimeRegionSend", mode = "x", desc = "Send region to REPL" },
      { "<leader>jl", "<Plug>SlimeLineSend", mode = "n", desc = "Send line to REPL" },
      { "<leader>jp", "<Plug>SlimeParagraphSend", mode = "n", desc = "Send paragraph to REPL" },
      { "<leader>jc", "<Plug>SlimeSendCell", mode = "n", desc = "Send cell to REPL" },
      {
        "<leader>jo",
        function()
          Snacks.terminal({ "julia", "--project=." }, { win = { position = "right" } })
        end,
        desc = "Open Julia REPL",
      },
    },
  },
}
