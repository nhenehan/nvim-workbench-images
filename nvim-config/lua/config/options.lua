-- Loaded before lazy.nvim starts. LazyVim sets leader=<space>, localleader=\ first.
local opt = vim.opt

-- Carried over from the previous config; per-language overrides live in autocmds.lua
opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true

opt.number = true
opt.relativenumber = true
opt.scrolloff = 8
opt.colorcolumn = "100"

-- Java/Maven target/ and CMake build/ trees are large and never worth searching
opt.wildignore:append({ "*/target/*", "*/build/*", "*/.git/*", "*/node_modules/*" })

vim.g.lazyvim_python_lsp = "basedpyright"
