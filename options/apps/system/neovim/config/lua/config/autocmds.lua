-- Autocommands

-- Briefly highlight the yanked text as a visual indicator as to what you yanked
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

----------------------------------------------------------------------------------------------------
-- File type settings
----------------------------------------------------------------------------------------------------

-- html files
local html_group = vim.api.nvim_create_augroup("HtmlSettings", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "FileType" }, {
  pattern = { "html", "*.html" },
  callback = function()
    vim.bo.filetype = "html"
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
  group = html_group,
})

-- make files
local make_group = vim.api.nvim_create_augroup("MakeSettings", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "FileType" }, {
  pattern = { "make", "Makefile", "*.make", "*.makefile" },
  callback = function()
    vim.bo.filetype = "make"
    vim.opt_local.expandtab = false -- don't expand tabs for Makefiles
  end,
  group = make_group,
})

-- markdown files
local md_group = vim.api.nvim_create_augroup("MarkdownSettings", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "FileType" }, {
  pattern = { "markdown", "*.md" },
  callback = function()
    vim.bo.filetype = "markdown"
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
  group = md_group,
})

-- yaml files
local yaml_group = vim.api.nvim_create_augroup("YamlSettings", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "FileType" }, {
  pattern = { "yaml", "*.yaml" },
  callback = function()
    vim.bo.filetype = "yaml"
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
  group = yaml_group,
})

-- xml files
local xml_group = vim.api.nvim_create_augroup("XmlSettings", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "FileType" }, {
  pattern = { "xml", "*.xml", "*.menu" },
  callback = function()
    vim.bo.filetype = "xml"
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
  group = xml_group,
})
