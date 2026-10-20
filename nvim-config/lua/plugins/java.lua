-- nvim-jdtls comes from the lang.java extra, which also installs jdtls,
-- java-debug-adapter and java-test via Mason and keeps lspconfig from starting
-- a second jdtls.
--
-- ForgeStudio caveat: it is a NetBeans Platform project (nbm-maven-plugin,
-- @ServiceProvider / layer.xml annotation processors). jdtls/m2e has no lifecycle
-- mapping for nbm-maven-plugin, so pom.xml will show "Plugin execution not covered
-- by lifecycle configuration" warnings -- those are noise. Run
-- `mvn -DskipTests install` at the ForgeStudio root BEFORE opening it, so that
-- target/generated-sources/annotations exists and jdtls picks it up as a source root.
-- Find installed JDKs and map them to Eclipse JavaSE-<n> execution environment names.
-- Marks the highest version as default; jdtls itself needs 21+ to run.
-- Only applies when the java extra is enabled for this image (NVIM_LANGS).
local langs = vim.env.NVIM_LANGS or "rust,clangd,cmake,java,julia,python"
if not langs:find("java", 1, true) then
  return {}
end

local function discover_jdks()
  local runtimes, best = {}, -1
  for _, dir in ipairs(vim.fn.glob("/usr/lib/jvm/*", false, true)) do
    local ver = dir:match("java%-(%d+)%-openjdk") or dir:match("jdk%-(%d+)")
    if ver and vim.fn.isdirectory(dir .. "/bin") == 1 then
      local n = tonumber(ver)
      if not vim.iter(runtimes):any(function(r) return r.name == "JavaSE-" .. ver end) then
        runtimes[#runtimes + 1] = { name = "JavaSE-" .. ver, path = dir }
        if n > best then best = n end
      end
    end
  end
  for _, r in ipairs(runtimes) do
    if r.name == "JavaSE-" .. tostring(best) then
      r.default = true
    end
  end
  return runtimes
end

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          configuration = {
            updateBuildConfiguration = "interactive",
            -- ForgeStudio targets release=17, so both runtimes must be offered.
            -- Discovered rather than hardcoded so this config also works inside the
            -- Docker workbench images, where the JDK paths differ.
            runtimes = discover_jdks(),
          },
          maven = { downloadSources = true },
          eclipse = { downloadSources = true },
          references = { includeDecompiledSources = true },
          implementationsCodeLens = { enabled = true },
          referencesCodeLens = { enabled = true },
          signatureHelp = { enabled = true },
          contentProvider = { preferred = "fernflower" },
          format = { enabled = true },
          errors = { incompleteClasspath = { severity = "warning" } },
          completion = {
            favoriteStaticMembers = {
              "org.junit.Assert.*",
              "org.junit.jupiter.api.Assertions.*",
              "org.mockito.Mockito.*",
              "org.openide.util.Lookup.*",
              "org.openide.util.NbBundle.*",
            },
            importOrder = { "java", "javax", "jakarta", "org", "com" },
          },
          sources = {
            organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
          },
        },
      })

      -- ForgeStudio is 16 modules; fieldagent is another handful. Give jdtls room.
      opts.cmd = opts.cmd or { vim.fn.exepath("jdtls") }
      vim.list_extend(opts.cmd, {
        "--jvm-arg=-Xmx4g",
        "--jvm-arg=-XX:+UseG1GC",
        "--jvm-arg=-XX:MaxMetaspaceSize=1g",
      })

      return opts
    end,
  },

  -- The extra ships a single attach-to-5005 config. Add the ports actually used
  -- by mvnDebug / nbm:run-platform and by WildFly.
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")
      dap.configurations.java = dap.configurations.java or {}
      table.insert(dap.configurations.java, {
        type = "java",
        request = "attach",
        name = "Attach :5005 (mvnDebug / nbm:run-platform)",
        hostName = "127.0.0.1",
        port = 5005,
      })
      table.insert(dap.configurations.java, {
        type = "java",
        request = "attach",
        name = "Attach :8787 (WildFly/JBoss)",
        hostName = "127.0.0.1",
        port = 8787,
      })
    end,
  },
}
