-- Local LLM + agent tooling for the llama workbench image. Off unless NVIM_LANGS
-- contains "llm", so the host keeps claudecode.nvim as its only AI integration.
--
--   codecompanion.nvim  chat / inline edits against the local llama-server (OpenAI
--                       compatible, served under the fixed alias "local"), plus ACP
--                       agents: claude_code (claude-agent-acp) and opencode.
--   llama.vim           FIM ghost-text completion from the same server's /infill.
--
-- <leader>a* belongs to claudecode and <leader>o* to overseer, so these live on
-- <leader>A*. llama.vim's defaults sit on <Tab> (blink.cmp) and <leader>ll* (which
-- would delay LazyVim's <leader>l), so they are moved to <M-*> and <leader>A*.
local langs = vim.env.NVIM_LANGS or ""
if not langs:find("llm", 1, true) then
  return {}
end

local llm_url = vim.env.LLM_URL or ("http://127.0.0.1:" .. (vim.env.LLM_PORT or "9090"))

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
    opts = {
      adapters = {
        http = {
          llamacpp = function()
            return require("codecompanion.adapters").extend("openai_compatible", {
              name = "llamacpp",
              formatted_name = "llama.cpp (local)",
              env = {
                url = llm_url,
                -- llama-server ignores the key; any env var that exists keeps the adapter happy.
                api_key = "TERM",
                chat_url = "/v1/chat/completions",
              },
              schema = { model = { default = "local" } },
            })
          end,
        },
        -- claude_code and opencode are built-in ACP adapters; they need only their
        -- CLIs on PATH (and CLAUDE_CODE_OAUTH_TOKEN / ANTHROPIC_API_KEY for Claude).
      },
      interactions = {
        chat = { adapter = "llamacpp" },
        inline = { adapter = "llamacpp" },
        cmd = { adapter = "llamacpp" },
      },
    },
    keys = {
      { "<leader>A", "", desc = "+llm", mode = { "n", "v" } },
      { "<leader>Ac", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle LLM chat", mode = { "n", "v" } },
      { "<leader>Aa", "<cmd>CodeCompanionActions<cr>", desc = "LLM actions", mode = { "n", "v" } },
      { "<leader>Ai", ":CodeCompanion ", desc = "LLM inline prompt", mode = { "n", "v" } },
      { "<leader>As", "<cmd>CodeCompanionChat Add<cr>", desc = "Add selection to LLM chat", mode = "v" },
      { "<leader>Ak", "<cmd>CodeCompanionChat adapter=claude_code<cr>", desc = "Claude Code agent chat" },
      { "<leader>Ao", "<cmd>CodeCompanionChat adapter=opencode<cr>", desc = "opencode agent chat" },
    },
  },

  {
    "ggml-org/llama.vim",
    -- Not lazy: it hooks VimEnter to start the FIM ring buffer.
    lazy = false,
    init = function()
      vim.g.llama_config = {
        endpoint_fim = llm_url .. "/infill",
        endpoint_inst = llm_url .. "/v1/chat/completions",
        model_fim = "local",
        model_inst = "local",
        show_info = 0,
        auto_fim = true,
        keymap_fim_trigger = "<leader>Af",
        keymap_fim_accept_full = "<M-l>",
        keymap_fim_accept_line = "<M-j>",
        keymap_fim_accept_word = "<M-w>",
        keymap_fim_next = "<M-]>",
        keymap_fim_prev = "<M-[>",
        keymap_inst_trigger = "<leader>AI",
        keymap_inst_rerun = "<leader>Ar",
        keymap_inst_continue = "<leader>An",
        keymap_inst_accept = "<M-l>",
        keymap_debug_toggle = "<leader>Ad",
      }
    end,
  },
}
