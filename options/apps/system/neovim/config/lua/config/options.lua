-- Options
vim.g.mapleader = " "                                 -- Set the <leader> key to a space

vim.opt.title = true                                  -- Change window title to your current buffer name
-- set encoding=UTF-8            " Required for vim-devicons to work correctly
vim.opt.autochdir = true                              -- Automatically switch working directory to current file
-- set backspace=2               " Configure backspace to work as normal same as =indent,eol,start
-- set clipboard+=unnamedplus    " Set all yanks to be copied to register * as well as register +
-- set formatoptions+=tqw        " Text formatting, a=auto formatting for t=text and w=paragraphs
-- set nobackup                  " Don't make a backup of a file when overwriting it
vim.opt.errorbells = false                            -- Disable error bells using vim.opt
vim.opt.cursorline = true                             -- Hightlight the current line your cursor is on
vim.opt.undofile = true                               -- Enables persistent .undo files for undo history
vim.opt.signcolumn = "yes:1"                          -- Always show the sign column (left gutter for errors)
vim.opt.scrolloff = 8                                 -- Keep 8 lines visible above/below the cursor for scrolling

-- Search
-- set nohlsearch                " Don't highlight matches with last search pattern
vim.opt.ignorecase = true                             -- Ignore case when searching
vim.opt.smartcase = true                              -- Search case sensative when you include case in your search

-- Mouse
-- set mouse=a                   " Enable mouse for all modes
-- set mousehide                 " Hide the mouse when typing text

-- Set numbering/status
vim.opt.number = true                                 -- Enable line numbers
vim.opt.ruler = true                                  -- Show position (row and column) at the bottom of the screen

-- Set tabbing/indenting
vim.opt.tabstop = 2                                   -- Number of spaces to use for the <Tab> character
vim.opt.shiftwidth = 2                                -- Number of spaces to use for each level of indenting >> or <<
vim.opt.softtabstop=2                                 -- How many columns a tab counts for, only used when expandtab is not set
vim.opt.expandtab = true                              -- Insert spaces instead of a literal tab character
vim.opt.wrap = false                                  -- Don't wrap long lines, instead let them scroll horizontally
-- set cindent                   " Enables automatic C program indenting
-- set cinkeys-=0#               " Solve for having # indented intuitively
-- set indentkeys-=0#            " Solve for having # indented intuitively
-- set autoindent                " Enables automatic C program indenting
-- set smartindent               " Indents according to blocks of code, 'nosmartindent'

-- set showmatch                 " When typing a closing parenthesis, bracket, or brace, shows match
-- set showmode                  " Show if you are in insert/command mode at the bottom of the screen
-- set spell spelllang=en_us     " Set spelling options
-- set nospell                   " Turn spelling off by default
-- set textwidth=101             " Maximum line length before wrapping; 0 means don't do this
-- set wrapmargin=10             " When width 0, this wraps if within this many spaces from right margin
-- set wildmode=longest,list     " Sets tab completion for command line similar to bash

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

-- Neovide's default vertical space between lines is too cramped. 3 matches Neovim's default look and 
-- feel when being used directly in the terminal
if vim.g.neovide then
  vim.opt.linespace = 3
end

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
