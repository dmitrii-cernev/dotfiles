return {
  "folke/todo-comments.nvim",
  opts = {
    keywords = {
      TODO = {
        icon = " ",
        color = "info",
        alt = { "todo" },
      },
      FIX = {
        icon = " ",
        color = "error",
        alt = { "fix", "bug", "fixme" },
      },
      -- repeat for HACK, NOTE, etc. if needed
    },
    highlight = {
      pattern = [[.*<(KEYWORDS)\s*:]], -- default good for highlighting
    },
  },
}
