-- Initialize configuration
require("config.options")               -- Load options from ../lua/config/options.lua
require("config.keymaps")               -- load keymaps from ../lua/config/keymaps.lua
--require("config.autocmds")              -- load keymaps from ../lua/config/autocmds.lua

-- Initialize plugin loading
vim.cmd.packadd("lz.n")                 -- don't rely on nvim to load lz.n
vim.cmd.packadd("vim-deus")             -- don't rely on nvim to load lz.n
require("lz.n").load("plugins")         -- load plugins from ./lua/plugins

vim.cmd.colorscheme("deus")
--vim.cmd.colorscheme("catppuccin-macchiato")
