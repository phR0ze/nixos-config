-- Initialize configuration
require("config.options")               -- Load options from ./config/options.lua
require("config.keymaps")               -- load keymaps from ./config/keymaps.lua
--require("config.autocmds")              -- load keymaps from ./config/autocmds.lua

-- Initialize plugin loading
vim.cmd.packadd("lz.n")                 -- load our package manager
require("lz.n").load("plugins")         -- load all other plugins from ./plugins

-- Set the target color scheme
vim.cmd.colorscheme("tokyonight-storm")
