return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      -- The lang extras already add rust, ron, cpp, cmake, java, julia, python,
      -- toml, json, markdown. These are the ones nothing else pulls in.
      ensure_installed = {
        "c",
        "make",
        "ninja",
        "xml", -- ForgeStudio layer.xml / pom.xml, omnischema schemas, Forge sources
        "yaml",
        "sql",
        "diff",
        "regex",
        "gitcommit",
        "gitignore",
      },
    },
  },
}
