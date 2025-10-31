return {
  -- [mini.icons](https://github.com/nvim-mini/mini.icons)
  -- Modern, minimal, pure lua replacement for nvim-web-devicons
  -- Can patch itself into plugins expecting nvim-web-devicons thus eliminating the need for both
  -- Has no external dependencies on Nerd Fonts like nvim-web-devicons does
  "mini.icons",                                     -- Lua result/pack/opt module name
  event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
  after = function()
    require("mini.icons").setup()                   -- Lua module path
    require("mini.icons").mock_nvim_web_devicons()  -- Setup compatibility layer for older plugins
    require('nvim-web-devicons')                    -- Load mini.pairs compatibility layer
  end,
}

-- LazyVim configuration
-- {
--   "nvim-mini/mini.icons",
--   lazy = true,
--   opts = {
--     file = {
--       [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
--       ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
--     },
--     filetype = {
--       dotenv = { glyph = "", hl = "MiniIconsYellow" },
--     },
--   },
--   init = function()
--     package.preload["nvim-web-devicons"] = function()
--       require("mini.icons").mock_nvim_web_devicons()
--       return package.loaded["nvim-web-devicons"]
--     end
--   end,
-- }
