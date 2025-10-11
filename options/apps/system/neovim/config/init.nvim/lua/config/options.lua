-- Options
vim.g.mapleader = " "                                 -- Set the <leader> key to a space

vim.opt.number = true                                 -- Enable line numbers
vim.opt.cursorline = true                             -- Hightlight the current line your cursor is on
vim.opt.undofile = true                               -- Enables persistent .undo files for undo history
vim.opt.shiftwidth = 2                                -- Number of spaces to use for each level of indenting >> or <<
vim.opt.tabstop = 2                                   -- Number of spaces to use for the <Tab> character
vim.opt.expandtab = true                              -- Insert spaces instead of a literal tab character
vim.opt.signcolumn = "yes:1"                          -- Always show the sign column (left gutter for errors)
vim.opt.scrolloff = 8                                 -- Keep 8 lines visible above/below the cursor for scrolling
vim.opt.ignorecase = true                             -- Ignore case when searching
vim.opt.smartcase = true                              -- Search case sensative when you include case in your search
vim.opt.wrap = false                                  -- Don't wrap long lines, instead let them scroll horizontally
vim.opt.swapfile = false                              -- Disable .swp file creation for recovery
vim.opt.confirm = true                                -- Prompt to save instead of erroring out
vim.opt.splitbelow = true                             -- Horizontal splits open below the current window
vim.opt.splitright = true                             -- Vertical splits open to the right of the current window
vim.opt.foldmethod = "expr"                           -- Use an expression to determine where to fold code
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"  -- Use Tree-sitter to calculate folds
vim.opt.foldtext = ""                                 -- Empty string will default to ... for fold text
vim.opt.foldlevel = 99                                -- Start with all folds open i.e. 99 means everything
vim.opt.jumpoptions = "stack"                         -- When jumping betweeen locations <C-o>, <C-i> use LIFO behavior
--vim.opt.wildmenu = true                               -- Enable enhanced command-line completion menu on :e <TAB>
--vim.opt.wildmode = "noselect:lastused,full"           -- Controls wildmenu to not auto-select, sort by most recent, show all
vim.opt.grepprg = "rg --vimgrep --hidden -g '!.git/*'"-- Sets :grep to use ripgrep instead of grep

-- Configures the global behavior of Neovim's built-in LSP diagnostics system to show errors/warnings 
-- as virtual text (inline in the buffer) with signs (in the gutter) and floating window popups.
vim.diagnostic.config({
  virtual_text = {
    source = true,
    prefix = "󰄛 ",
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
  },
  float = { source = true },
  jump = { float = true },
  severity_sort = true,
  update_in_insert = true,
})
