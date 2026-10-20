-- nvim-dap, dap-ui, dap-virtual-text and mason-nvim-dap all come from the dap.core
-- extra, along with the <leader>d* keymaps. This adds the pieces it leaves out.
return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>dL",
        function()
          require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
        end,
        desc = "Log Point",
      },
      {
        "<leader>dH",
        function()
          require("dap").set_breakpoint(nil, vim.fn.input("Hit count: "), nil)
        end,
        desc = "Hit-Count Breakpoint",
      },
      {
        "<leader>dx",
        function() require("dap").clear_breakpoints() end,
        desc = "Clear All Breakpoints",
      },
      {
        "<leader>dQ",
        function()
          require("dap").list_breakpoints()
          vim.cmd("copen")
        end,
        desc = "List Breakpoints (quickfix)",
      },
    },
  },

  {
    "rcarriga/nvim-dap-ui",
    opts = {
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.35 },
            { id = "breakpoints", size = 0.15 },
            { id = "stacks", size = 0.25 },
            { id = "watches", size = 0.25 },
          },
          size = 50,
          position = "left",
        },
        {
          elements = {
            { id = "repl", size = 0.5 },
            { id = "console", size = 0.5 },
          },
          size = 12,
          position = "bottom",
        },
      },
      controls = { enabled = true, element = "repl" },
      floating = { border = "rounded" },
    },
  },

  {
    "theHamsta/nvim-dap-virtual-text",
    opts = {
      enabled = true,
      highlight_changed_variables = true,
      show_stop_reason = true,
      commented = false,
      virt_text_pos = "eol",
      all_frames = false,
      -- Rust enums and C++ STL containers render enormous inline values; truncate.
      display_callback = function(variable)
        local v = variable.value:gsub("%s+", " ")
        if #v > 60 then
          v = v:sub(1, 57) .. "..."
        end
        return " = " .. v
      end,
    },
  },
}
