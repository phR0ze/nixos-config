-- stylua: ignore
-- -------------------------------------------------------------------------------------------------
-- General options
-- [Kickstart.nvim for more options](https://github.com/nvim-lua/kickstart.nvim)
-- -------------------------------------------------------------------------------------------------
vim.g.mapleader = " "                                 -- Set the <leader> key to a space
vim.g.maplocalleader = " " -- Set the <leader> key to a space
vim.g.have_nerd_font = true -- ?

vim.opt.title = true -- Change window title to your current buffer name
-- set encoding=UTF-8            " Required for vim-devicons to work correctly
vim.opt.autochdir = true -- Automatically switch working directory to current file
vim.opt.backspace = { "indent", "eol", "start" } -- Configure backspace to work as normal
vim.opt.clipboard = { "unnamed", "unnamedplus" } -- Set all yanks to be copied to register * as well as register +
vim.opt.errorbells = false -- Disable error bells using vim.opt
vim.opt.confirm = true -- Prompt to save instead of erroring out
vim.opt.undofile = true -- Enables persistent .undo files for undo history
vim.opt.swapfile = false -- Disable .swp file creation for recovery

-- UI changes
vim.opt.showmode = false -- Don't need this as we already have lualine showing it
vim.opt.signcolumn = "yes:1" -- Always show the sign column (left gutter for errors)

-- Search
vim.opt.ignorecase = true -- Ignore case when searching
vim.opt.smartcase = true -- Search case sensative when you include case in your search

-- Mouse
vim.opt.mouse = "a" -- Enable mouse for all modes
vim.opt.mousehide = true -- Hide the mouse when typing text only impacts GUI not TUI

-- Set numbering/status
vim.opt.cursorline = true -- Hightlight the current line your cursor is on
vim.opt.number = true -- Enable line numbers
vim.opt.ruler = true -- Show position (row and column) at the bottom of the screen
vim.opt.scrolloff = 8 -- Keep 8 lines visible above/below the cursor for scrolling

-- Display special characters
vim.opt.list = true
vim.opt.listchars = { -- Display whitespace characters as these special symbols
	tab = "» ",
	trail = "·",
	nbsp = "␣",
}

-- Set tabbing/indenting
vim.opt.tabstop = 2 -- Number of spaces to use for the <Tab> character
vim.opt.shiftwidth = 2 -- Number of spaces to use for each level of indenting >> or <<
vim.opt.softtabstop = 2 -- How many columns a tab counts for, only used when expandtab is not set
vim.opt.expandtab = true -- Insert spaces instead of a literal tab character
vim.opt.wrap = false -- Don't wrap long lines, instead let them scroll horizontally
-- vim.opt.cindent = true                                -- Enables automatic C program indenting
-- vim.opt.cinkeys-=0#               " Solve for having # indented intuitively
-- set indentkeys-=0#            " Solve for having # indented intuitively
vim.opt.smarttab = true -- Navigate tabstop spaces by when it detects them
vim.opt.autoindent = true -- Enables automatic C program indenting
vim.opt.smartindent = true -- Indents according to blocks of code, 'nosmartindent'
vim.opt.breakindent = true -- Indent correctly when a line goes to long and breaks

-- Text Wrapping
vim.opt.showmatch = true -- When typing a closing parenthesis, bracket, or brace, shows match
-- set spell spelllang=en_us     " Set spelling options
-- set nospell                   " Turn spelling off by default
vim.opt.textwidth = 101 -- Maximum line length before wrapping; 0 means don't do this
vim.opt.wrapmargin = 10 -- When width 0, this wraps if within this many spaces from right margin
-- set wildmode=longest,list     " Sets tab completion for command line similar to bash

vim.opt.splitbelow = true -- Horizontal splits open below the current window
vim.opt.splitright = true -- Vertical splits open to the right of the current window
vim.opt.jumpoptions = "stack" -- When jumping betweeen locations <C-o>, <C-i> use LIFO behavior
--vim.opt.wildmenu = true                               -- Enable enhanced command-line completion menu on :e <TAB>
--vim.opt.wildmode = "noselect:lastused,full"           -- Controls wildmenu to not auto-select, sort by most recent, show all
vim.opt.grepprg = "rg --vimgrep --hidden -g '!.git/*'" -- Sets :grep to use ripgrep instead of grep

-- Neovide's default vertical space between lines is too cramped. 3 matches Neovim's default look and
-- feel when being used directly in the terminal
if vim.g.neovide then
	vim.opt.linespace = 3
end
