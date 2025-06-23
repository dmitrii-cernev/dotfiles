
-- Enable line numbers
vim.opt.number = true

-- Enable relative line numbers
vim.opt.relativenumber = true

-- Enable syntax highlighting and filetype detection
vim.cmd('syntax on')
vim.cmd('filetype plugin indent on')

-- Tabs and indentation
vim.opt.tabstop = 4        -- Number of spaces that a <Tab> counts for
vim.opt.shiftwidth = 4     -- Number of spaces to use for autoindent
vim.opt.expandtab = true   -- Use spaces instead of tabs
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Search settings
vim.opt.hlsearch = true        -- Highlight search results
vim.opt.incsearch = true       -- Show matches as you type
vim.opt.ignorecase = true      -- Case-insensitive search...
vim.opt.smartcase = true       -- ...unless capital letters are used

-- Show matching parentheses/brackets
vim.opt.showmatch = true

-- Display command being typed
vim.opt.showcmd = true

-- Use system clipboard if available
vim.opt.clipboard = 'unnamedplus'

-- Allow backspacing over everything in insert mode
vim.opt.backspace = { 'indent', 'eol', 'start' }

-- Autohide command line when not in use
-- hide command-line when unused
-- vim.o.cmdheight = 0

vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand("~/.config/nvim/undodir")

-- make cmdheight 1 when you enter : or /
-- vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineChanged", "CmdlineLeave" }, {
--   callback = function(event)
--     if event.event == "CmdlineEnter" then
--       vim.o.cmdheight = 1
--     elseif event.event == "CmdlineLeave" then
--       vim.o.cmdheight = 0
--     end
--   end,
-- })

-- optional: disable built-in showcmd (you get partial keys in the statusline already)
vim.o.showcmd = false

vim.opt.wrap = false
