return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },

    config = function()
        require("neo-tree").setup({
            filesystem = {
                filtered_items = {
                    visible = true, -- Show hidden files by default
                    hide_dotfiles = false,
                    hide_gitignored = false,
                },
            },
        })

        vim.keymap.set("n", "<leader>e", function()
            if vim.bo.filetype == "neo-tree" then
                -- if we're already in Neo-tree, close it (focus returns to the file)
                vim.cmd("Neotree close")
            else
                -- otherwise open (or focus) the filesystem tree and reveal the current file
                vim.cmd("Neotree source=filesystem reveal=true position=left")
            end
        end, { silent = true, noremap = true, desc = "Toggle File Explorer" })
    end,

}
