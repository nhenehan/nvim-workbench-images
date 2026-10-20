-- LazyVim splits treesitter textobjects in two:
--   * movement  (]f [f ]c [c ]a [a) -> nvim-treesitter-textobjects
--   * selection (af if ac ic ao io) -> mini.ai
-- Extend mini.ai rather than adding select keymaps to treesitter-textobjects,
-- which would collide.
return {
  {
    "nvim-mini/mini.ai",
    opts = function(_, opts)
      local ai = require("mini.ai")
      opts.custom_textobjects = vim.tbl_extend("force", opts.custom_textobjects or {}, {
        a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
        ["="] = ai.gen_spec.treesitter({ a = "@assignment.outer", i = "@assignment.rhs" }),
        C = ai.gen_spec.treesitter({ a = "@comment.outer", i = "@comment.inner" }),
        r = ai.gen_spec.treesitter({ a = "@return.outer", i = "@return.inner" }),
      })
      return opts
    end,
  },
}
