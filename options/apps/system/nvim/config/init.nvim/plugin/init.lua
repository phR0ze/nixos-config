-- Initialize loading of all modules and plugins
print('init.nvim - loaded!')
require("config.options")               -- Load options from ../lua/config/options.lua
require("config.keymaps")               -- load keymaps from ../lua/config/keymaps.lua

require("lz.n").load("plugins")         -- load plugins from ./lua/plugins
