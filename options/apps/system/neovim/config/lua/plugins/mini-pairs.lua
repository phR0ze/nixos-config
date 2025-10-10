return {
  {
    "mini-pairs",
    event = "DeferredUIEnter",
    after = function()
      require("mini.pairs").setup()
    end,
  },
}
