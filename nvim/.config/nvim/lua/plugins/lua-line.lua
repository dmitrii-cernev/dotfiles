return {
    "nvim-lualine/lualine.nvim",
    config = function()
        require('lualine').setup {
            options = {
                theme = 'catppuccin-macchiato',
                -- keep icons_enabled = true if you still want other icons
                icons_enabled = true,
            },
            sections = {
                -- here you can fill out the other sections however you like…
                lualine_a = { 'mode' },
                lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = { 'filename' },

                -- override lualine_x to drop encoding and fileformat:
                lualine_x = { 'filetype' },

                lualine_y = { 'progress' },
                lualine_z = { 'location' },
            },
        }
    end,
}
