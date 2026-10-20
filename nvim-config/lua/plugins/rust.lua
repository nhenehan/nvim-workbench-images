-- The lang.rust extra already supplies rustaceanvim, crates.nvim, codelldb and the
-- neotest adapter, and it disables lspconfig's rust_analyzer so rustaceanvim owns the
-- server. Do NOT configure rust_analyzer through lspconfig anywhere.
-- Only applies when the rust extra is enabled for this image (NVIM_LANGS).
local langs = vim.env.NVIM_LANGS or "rust,clangd,cmake,java,julia,python"
if not langs:find("rust", 1, true) then
  return {}
end

return {
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            -- The extra only sets `checkOnSave = true`, which runs plain `cargo check`.
            -- Clippy needs the separate `check` table; the old config's
            -- `checkOnSave = { command = "clippy" }` is the pre-2024 form and is ignored.
            check = {
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
            cargo = {
              features = "all",
              buildScripts = { enable = true },
              -- Separate target dir so a `cargo build` in a terminal doesn't
              -- invalidate rust-analyzer's cache (matters on the Forge workspace).
              targetDir = true,
            },
            procMacro = { enable = true },
            inlayHints = {
              lifetimeElisionHints = { enable = "skip_trivial", useParameterNames = true },
              closureReturnTypeHints = { enable = "with_block" },
            },
          },
        },
      },
    },
  },

  {
    "Saecki/crates.nvim",
    keys = {
      { "<leader>cu", function() require("crates").upgrade_crate() end, ft = "toml", desc = "Upgrade crate" },
      { "<leader>cU", function() require("crates").upgrade_all_crates() end, ft = "toml", desc = "Upgrade all crates" },
      { "<leader>cv", function() require("crates").show_versions_popup() end, ft = "toml", desc = "Crate versions" },
      { "<leader>cF", function() require("crates").show_features_popup() end, ft = "toml", desc = "Crate features" },
    },
  },
}
