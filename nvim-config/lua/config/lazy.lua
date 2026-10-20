local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Which language extras to load, so a C++ workbench image does not carry Java tooling.
-- Unset on the host, which loads everything. "llm" gates lua/plugins/llm.lua.
local langs = vim.env.NVIM_LANGS or "rust,clangd,cmake,java,julia,python"
local want = {}
for lang in langs:gmatch("[^,%s]+") do
  want[lang] = true
end

local spec = {
  { "LazyVim/LazyVim", import = "lazyvim.plugins" },
}

-- ── languages ─────────────────────────────────────────────────────────
for _, lang in ipairs({ "rust", "clangd", "cmake", "java", "julia", "python" }) do
  if want[lang] then
    spec[#spec + 1] = { import = "lazyvim.plugins.extras.lang." .. lang }
  end
end

vim.list_extend(spec, {
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.toml" },
  { import = "lazyvim.plugins.extras.lang.markdown" },
  { import = "lazyvim.plugins.extras.lang.git" },

  -- ── debugging & testing ─────────────────────────────────────────────
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.test.core" },

  -- ── refactoring & navigation (refactoring.nvim needs nvim >= 0.12) ──
  { import = "lazyvim.plugins.extras.editor.refactoring" },
  { import = "lazyvim.plugins.extras.editor.aerial" },
  { import = "lazyvim.plugins.extras.editor.inc-rename" },
  { import = "lazyvim.plugins.extras.editor.illuminate" },
  { import = "lazyvim.plugins.extras.editor.overseer" },

  -- ── ai ──────────────────────────────────────────────────────────────
  { import = "lazyvim.plugins.extras.ai.claudecode" },

  -- ── ui ──────────────────────────────────────────────────────────────
  { import = "lazyvim.plugins.extras.ui.treesitter-context" },
  { import = "lazyvim.plugins.extras.ui.indent-blankline" },

  -- ── local overrides ─────────────────────────────────────────────────
  { import = "plugins" },
})

require("lazy").setup({
  spec = spec,
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "tokyonight", "habamax" } },
  -- Workbench containers are ephemeral and pinned to lazy-lock.json; no update checks there.
  checker = { enabled = vim.env.NVIM_CONTAINER == nil, notify = false },
  performance = {
    rtp = { disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
  },
})
