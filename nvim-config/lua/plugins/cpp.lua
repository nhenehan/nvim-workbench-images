-- clangd comes from the lang.clangd extra; cmake-tools + neocmake from lang.cmake.
-- Prefer the distro clangd, which matches the distro gcc headers. Falls back to
-- whatever is on PATH so this config also works in the Docker workbench images.
-- Only applies when the clangd extra is enabled for this image (NVIM_LANGS).
local langs = vim.env.NVIM_LANGS or "rust,clangd,cmake,java,julia,python"
if not langs:find("clangd", 1, true) then
  return {}
end

local function system_clangd()
  if vim.fn.executable("/usr/bin/clangd") == 1 then
    return "/usr/bin/clangd"
  end
  local found = vim.fn.exepath("clangd")
  return found ~= "" and found or "clangd"
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          -- Pin to the system clangd 18.1.3, which matches the system gcc-13 headers.
          -- A Mason-installed clangd 20.x would emit spurious diagnostics on <version>.
          mason = false,
          cmd = {
            system_clangd(),
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            "--all-scopes-completion",
            "--pch-storage=memory",
            "-j=4",
          },
        },
      },
    },
  },

  {
    "Civitasv/cmake-tools.nvim",
    opts = {
      cmake_command = "cmake",
      cmake_build_directory = "build",
      cmake_generate_options = {
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
        "-DCMAKE_BUILD_TYPE=Debug",
      },
      cmake_soft_link_compile_commands = true,
      cmake_dap_configuration = {
        name = "cpp",
        type = "codelldb",
        request = "launch",
        stopOnEntry = false,
        runInTerminal = true,
        console = "integratedTerminal",
      },
      cmake_executor = { name = "quickfix" },
      cmake_runner = { name = "terminal" },
    },
    keys = {
      { "<leader>cmg", "<cmd>CMakeGenerate<cr>", desc = "CMake Generate" },
      { "<leader>cmb", "<cmd>CMakeBuild<cr>", desc = "CMake Build" },
      { "<leader>cmr", "<cmd>CMakeRun<cr>", desc = "CMake Run" },
      { "<leader>cmd", "<cmd>CMakeDebug<cr>", desc = "CMake Debug" },
      { "<leader>cms", "<cmd>CMakeSelectBuildTarget<cr>", desc = "CMake Select Build Target" },
      { "<leader>cmt", "<cmd>CMakeSelectLaunchTarget<cr>", desc = "CMake Select Launch Target" },
      { "<leader>cmc", "<cmd>CMakeClean<cr>", desc = "CMake Clean" },
    },
  },

  -- The extra's C/C++ DAP configs prompt for a bare executable path. Add one that
  -- pre-fills the CMake build dir, plus a system lldb-dap fallback adapter.
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")

      dap.adapters.lldb_dap = {
        type = "executable",
        command = vim.fn.exepath("lldb-dap-18") ~= "" and vim.fn.exepath("lldb-dap-18")
          or (vim.fn.exepath("lldb-dap") ~= "" and vim.fn.exepath("lldb-dap") or "lldb-dap"),
        name = "lldb_dap",
      }

      for _, lang in ipairs({ "c", "cpp" }) do
        dap.configurations[lang] = dap.configurations[lang] or {}
        table.insert(dap.configurations[lang], 1, {
          name = "Launch from build/ (with args)",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/build/", "file")
          end,
          args = function()
            return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          terminal = "integrated",
        })
      end
    end,
  },
}
