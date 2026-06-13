-- === init.lua (for Neovim 0.11.4) ===
-- Bootstrap packer if not installed
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({"git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end
local packer_bootstrap = ensure_packer()

require("packer").startup(function(use)
  use "wbthomason/packer.nvim"
  use {"nvim-tree/nvim-web-devicons"}
  use {"nvim-tree/nvim-tree.lua"}
  use {"neovim/nvim-lspconfig"}
  use {"nvim-treesitter/nvim-treesitter"}
  use {"hrsh7th/nvim-cmp"}
  use {"hrsh7th/cmp-nvim-lsp"}
  use {"nvim-lualine/lualine.nvim"}  -- 🔥 Statusline
  if packer_bootstrap then require("packer").sync() end
end)

-- === UI Settings ===
vim.o.number = true
vim.o.relativenumber = true
vim.o.termguicolors = true
vim.cmd [[syntax enable]]

-- === Web Devicons ===
require("nvim-web-devicons").setup {
  default = true,
--  override_by_extension = {
--    ["rs"] = { icon = "🦀", color = "--dea584", name = "Rust" },
--    ["jl"] = { icon = "🪶", color = "--a270ba", name = "Julia" },
--  },
}

-- === Treesitter ===
require("nvim-treesitter.configs").setup {
  ensure_installed = { "rust", "lua", "bash", "json", "julia" },
  highlight = { enable = true },
}

-- === LSP ===
local capabilities = require("cmp_nvim_lsp").default_capabilities()
-- https://github.com/Zeioth/compiler.nvim - build within nvim
vim.lsp.config("rust_analyzer", {
  capabilities = capabilities,
})
vim.lsp.enable("rust_analyzer")
  
-- vim.lsp.config('julials', {
--     cmd = {
--         "julia",
--         "--project=".."~/.julia/environments/lsp/",
--         "--startup-file=no",
--         "--history-file=no",
--         "-e", [[
--             using Pkg
--             Pkg.instantiate()
--             using LanguageServer
--         depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
--         project_path = let
--             dirname(something(
--                 ## 1. Finds an explicitly set project (JULIA_PROJECT)
--                 Base.load_path_expand((
--                     p = get(ENV, "JULIA_PROJECT", nothing);
--                         p === nothing ? nothing : isempty(p) ? nothing : p
--                     )),
--                         ## 2. Look for a Project.toml file in the current working directory,
--                         ##    or parent directories, with $HOME as an upper boundary
--                         Base.current_project(),
--                         ## 3. First entry in the load path
--                         get(Base.load_path(), 1, nothing),
--                         ## 4. Fallback to default global environment,
--                         ##    this is more or less unreachable
--                     Base.load_path_expand("@v#.#"),
--                 ))
--             end
--                    @info "Running language server" VERSION pwd() project_path depot_path
--                    server = LanguageServer.LanguageServerInstance(stdin, stdout, project_path, depot_path)
--        server.runlinter = true
--            run(server)
--        ]]
--    },
--    filetypes = { 'julia' },
--    root_markers = { "Project.toml", "JuliaProject.toml" },
--    settings = {}
--})
vim.lsp.config("julials", {
  capabilities = capabilities,
})
vim.lsp.enable("julials")


-- vim.lsp.config("julials", {
--  capabilities = capabilities,
--})

-- === Completion ===
local cmp = require("cmp")
cmp.setup({
  mapping = cmp.mapping.preset.insert(),
  sources = {{ name = "nvim_lsp" }},
})

-- === File Explorer (NvimTree) ===
require("nvim-tree").setup {
  renderer = {
    highlight_git = true,
    highlight_opened_files = "name",
    indent_markers = { enable = true },
    icons = {
      show = {
        file = true,
        folder = true,           -- <-- ensure folders are shown
        folder_arrow = true,
        git = true,
      },
    },
  },
  update_focused_file = { enable = true, update_cwd = true },
  git = { enable = true },
}
vim.api.nvim_set_keymap("n", "<C-n>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })

-- === Lualine ===
require("lualine").setup {
  options = {
    icons_enabled = true,
    theme = "auto",
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
    disabled_filetypes = {},
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "encoding", "fileformat", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
}
