-- coder/claudecode.nvim comes from the ai.claudecode extra with its <leader>a*
-- keymaps. It runs a WebSocket server inside Neovim speaking the same protocol as
-- the official IDE extensions, so the `claude` CLI in the terminal split connects
-- to it -- selections carry file/line context and edits arrive as native diff buffers.
return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      auto_start = true,
      log_level = "info",
      focus_after_send = false,
      track_selection = true,
      visual_demotion_delay_ms = 50,
      terminal = {
        provider = "snacks",
        split_side = "right",
        split_width_percentage = 0.35,
        auto_close = true,
        auto_insert = true,
        fix_streamed_paste = "auto",
      },
      diff_opts = {
        layout = "vertical",
        open_in_new_tab = false,
        keep_terminal_focus = false,
        auto_resize_terminal = true,
      },
    },
    keys = {
      -- lazy.nvim replaces (not merges) the `keys` list across spec fragments for the
      -- same plugin, so the extra's own keymaps have to be repeated here explicitly or
      -- they silently disappear -- including <leader>ac, the one that starts Claude.
      { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
      -- The extra's ft list predates snacks.picker, which is what LazyVim now uses.
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "snacks_picker_list", "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
      },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>aS", "<cmd>ClaudeCodeStatus<cr>", desc = "Claude status" },
      { "<leader>aX", "<cmd>ClaudeCodeStop<cr>", desc = "Stop Claude server" },
      { "<leader>aD", "<cmd>ClaudeCodeCloseAllDiffs<cr>", desc = "Close all diffs" },
    },
  },
}
