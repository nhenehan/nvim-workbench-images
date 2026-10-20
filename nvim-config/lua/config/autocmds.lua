-- LazyVim's own autocmds load first; this file only adds to them.
local function augroup(name)
  return vim.api.nvim_create_augroup("nh_" .. name, { clear = true })
end

-- Per-language indentation. The global default is 2; these languages want 4.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("indent"),
  pattern = { "c", "cpp", "java", "rust", "julia" },
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.expandtab = true
  end,
})

-- Modelica: filetype detection only. No parser or language server exists that is
-- worth wiring up, and there is no Modelica code on this machine yet.
vim.filetype.add({ extension = { mo = "modelica" } })

-- NOT carried over from the old init.lua: a VimEnter autocmd that ran :TSUpdate on
-- every single startup. lazy.nvim's build hook handles parser updates on :Lazy update.
