return {
  "rcarriga/nvim-dap-ui",
  opts = function(_, opts)
    -- remove unwanted elements:
    opts.layouts = {
      {
        elements = {
          "scopes",
          "breakpoints",
          "repl",
          "watches",
        },
        size = 40,
        position = "left",
      },
      {
        elements = {
          "console",
        },
        size = 10,
        position = "bottom",
      },
      -- no second layout at all means no repl, no console
    }
    return opts
  end,
}
