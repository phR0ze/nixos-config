-- Autocommands
vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = "grep",
  callback = function()
    vim.cmd.cwindow()
  end,
})

vim.api.nvim_create_autocmd("CmdlineChanged", {
  pattern = "*",
  callback = function()
    local cmdline_cmd = vim.fn.split(vim.fn.getcmdline(), " ")[1]
    if cmdline_cmd == "find" or cmdline_cmd == "b" then
      vim.fn.wildtrigger()
    end
  end,
})

-- Set custom settings for markdown files
local md_group = vim.api.nvim_create_augroup("MarkdownSettings", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "FileType" }, {
  pattern = { "*.markdown", "*.mdown", "*.mkd", "*.mkdn", "*.mdwn", "*.md", "markdown" },
  callback = function()
    -- Ensure buffer filetype is markdown
    vim.bo.filetype = "markdown"

    -- 2-space indentation
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
  group = md_group,
})
