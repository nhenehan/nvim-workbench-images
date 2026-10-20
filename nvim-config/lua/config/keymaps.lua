-- LazyVim's default keymaps load first; this file only adds and overrides.
local map = vim.keymap.set

-- Muscle memory from the old config. LazyVim's own explorer is <leader>e.
map("n", "<C-n>", function() Snacks.explorer() end, { desc = "Explorer (root)" })

-- The old <leader>q = :q is dropped: LazyVim uses <leader>q as a group prefix
-- (quit/session). Use :q, or <leader>qq to quit all. <leader>w still saves.

-- Maven, for the ForgeStudio / fieldagent work
map("n", "<leader>mb", "<cmd>!mvn -q -DskipTests install<cr>", { desc = "Maven install" })
map("n", "<leader>mt", "<cmd>!mvn test<cr>", { desc = "Maven test" })
