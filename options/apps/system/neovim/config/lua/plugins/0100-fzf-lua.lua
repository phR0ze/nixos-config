return {
  -- Fast fuzzy finder - better than telescope
  -- depends on mini.icons and optionally lsps
  "fzf-lua",
  cmd = "FzfLua",
  keys = {
    --{ "<leader><leader>", "<cmd>FzfLua buffers<cr>", desc = "Find in open buffers" },
    --{ "<leader>fb", "<cmd>FzfLua builtin<cr>", desc = "Find builtin fuzzy finders" },
    --{ "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files in Current Working Directory" },
    --{ "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Find grep through files" },
    --{ "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "Find help for Neovim" },
    --{ "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = "Find key maps" },
    --{ "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Find recent files" },
    { "<leader>fR", "<cmd>FzfLua resume<cr>", desc = "Find resume recent find" },
    { "<leader>fw", "<cmd>FzfLua grep_cword<cr>", desc = "Find word" },

    -- LazyVim bindings, maybe not useful
    { "<leader>ss", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Find symbol" },
    --{ "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Find symbol" },
    { "grr", "<cmd>FzfLua lsp_references<cr>", desc = "Lsp references" },
    { "grt", "<cmd>FzfLua lsp_typedefs<cr>", desc = "Lsp references" },
    { "gd", "<cmd>FzfLua lsp_definitions<cr>", desc = "Lsp definitions" },
    {
      "<leader>sS",
      function()
        require("fzf-lua").lsp_live_workspace_symbols({
          formatter = "path.filename_first",
        })
      end,
      desc = "Find global symbol",
    },
  },
  after = function()
    require("fzf-lua").setup({
      winopts = {
        preview = {
          layout = "vertical",
        },
      },
      fzf_colors = true,
    })
    require("fzf-lua").register_ui_select()
  end,
}
