return {
  "nvim-flutter/flutter-tools.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim", -- optional for vim.ui.select
  },
  config = function()
    require("flutter-tools").setup({})

    -- flutter-tools helpers
    local map = vim.keymap.set
    map("n", "<leader>Fd", "<cmd>FlutterDevices<cr>", { desc = "Flutter: Devices" })
    map("n", "<leader>Fr", "<cmd>FlutterReload<cr>", { desc = "Flutter: Hot Reload" })
    map("n", "<leader>FD", "<cmd>FlutterDetach<cr>", { desc = "Flutter: Detach" })
    map("n", "<leader>Fl", "<cmd>FlutterLogToggle<cr>", { desc = "Flutter: Toggle Logs" })
  end,
}
