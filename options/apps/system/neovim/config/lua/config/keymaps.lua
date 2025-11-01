-- Key Mappings
-- n Normal mode map. Defined using :nmap or nnoremap
-- i Insert mode map. Defined using :imap or inoremap
-- v Visual and select mode map. Defined using :vmap or vnoremap
-- x Visual mode map. Defined using :xmap or xnoremap
-- s Select mode map. Defined using :smap or snoremap
-- c Command-line mode map. Defined using :cmap or cnoremap
-- noremap ignores other mappings - always use this mode

-- Useful for clearing search results triggered with / or * without needing :nohlsearch
-- normal: clears highlighted search matches
--         exits any mode by pressing <Esc> again
vim.keymap.set("n", "<esc>", "<cmd>nohl<cr><esc>")

-- Switch to the next or previous buffer
vim.keymap.set("n", "<tab>", "<cmd>bn<cr>")
vim.keymap.set("n", "<s-tab>", "<cmd>bp<cr>")

-- Indent a full selected block and then reselect the block
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")

-- Yank and Paste with the system clipboard
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p')

-- Filter the quick fixes list by pattern
-- vim.keymap.set("n", "<leader>cf", ":Cfilter ")
--
-- -- Open the quick fix window
-- vim.keymap.set("n", "<leader>cc", ":copen<cr>")
--
-- -- Move to the older quick fix window
-- vim.keymap.set("n", "<leader>co", ":colder<cr>")
--
-- -- Move to the newer quick fix window
-- vim.keymap.set("n", "<leader>cn", ":cnewer<cr>")
--
-- vim.keymap.set("n", "<leader>ff", ":find<space>")
-- vim.keymap.set("n", "<leader>fb", ":b<space>")
-- vim.keymap.set("n", "<leader>sg", ":sil grep ''<left>")
--
-- vim.keymap.set("n", "grn", ":LspRename <c-r><c-w>")
-- vim.keymap.set("n", "<leader>sS", ":LspSymbol ")
--
-- vim.api.nvim_create_user_command("LspRename", function(opts)
--   vim.lsp.buf.rename(opts.args)
-- end, { nargs = 1 })
--
-- vim.api.nvim_create_user_command("LspSymbol", function(opts)
--   vim.lsp.buf.workspace_symbol(opts.args)
-- end, { nargs = 1 })
--
-- vim.api.nvim_create_user_command("StripAnsi", function(opts)
--   vim.cmd([[ %s/\e\[[0-9;]*m//g ]])
-- end, {})
