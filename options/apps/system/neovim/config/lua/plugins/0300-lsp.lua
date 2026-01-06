return {
  {
    -- ---------------------------------------------------------------------------------------------
    -- [crates.nvim](https://github.com/saecki/crates.nvim)
    -- manage crates.io dependencies with autocompletion of versions and features
    -- no dependencies
    -- ---------------------------------------------------------------------------------------------
    "crates.nvim",
    event = "BufRead Cargo.toml",
    after = function()
      require("crates").setup({})
    end,
  },
  {
    -- ---------------------------------------------------------------------------------------------
    -- [figet.nvim](https://github.com/j-hui/fidget.nvim)
    -- shows LSP logging output in the bottom right hand side
    -- no dependencies
    -- ---------------------------------------------------------------------------------------------
    "fidget.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("fidget").setup({
        notification = { override_vim_notify = true },
      })
    end,
  },
  {
    -- ---------------------------------------------------------------------------------------------
    -- [lazydev.nvim](https://github.com/folke/lazydev.nvim/releases)
    -- Ready made Lua LSP configuration to fix some LSP issues
    -- no dependencies
    -- ---------------------------------------------------------------------------------------------
    "lazydev.nvim",
    after = function()
      require("lazydev").setup({
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      })
    end,
  },
  {
    -- ---------------------------------------------------------------------------------------------
    -- nvim-lspconfig is a lua plugin to assist in LSP configuration
    -- * depends on treesitter, snacks.picker, mini.icons
    -- * configure via vim.lsp.config commands according to the docs
    -- ---------------------------------------------------------------------------------------------
    "nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile", "FileType" },
    before = function()
      require("lz.n").trigger_load("nvim-treesitter")
      require("lz.n").trigger_load("snacks.nvim")
      require("lz.n").trigger_load("lazydev.nvim")
    end,
    after = function()
      -- Configure all LSP floating windows with outline and rounded corners
      vim.lsp.util.open_floating_preview = (function(orig)
        return function(contents, syntax, opts, ...)
          opts = opts or {}
          opts.border = opts.border or "rounded"
          return orig(contents, syntax, opts, ...)
        end
      end)(vim.lsp.util.open_floating_preview)

      -- Configure LSP diagnostics system to show errors/warnings with a floating window when
      -- invoked with `gl` and signs in the gutter.
      vim.diagnostic.config({
        -- Not using virtual text (i.e. inline) as it's always clipped off and unreadable
        --virtual_text = { source = true, prefix = "󰄛 ", },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = " ",
          },
        },
        -- float rounded provides a nice window that can be invoked with my 'gl' key map
        float = {
          border = "rounded", -- add a rounded border around the flowing window
          source = true,
        },
        jump = { float = true },
        severity_sort = true, -- sort diagnostics by severity if more than one in a window
        update_in_insert = true,
      })

      -- Check for and use inlay hints if supported
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(true, { buffer = args.buf })
          end
        end,
      })

      -- Configure additional LSP key mappings not covered in `0100-snacks-nvim.lua`
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          -- Code Action keymaps
          vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { buffer = event.buf, desc = "LSP: [C]ode [R]ename" })
          vim.keymap.set(
            { "n", "x" },
            "<leader>ca",
            vim.lsp.buf.code_action,
            { buffer = event.buf, desc = "LSP: [C]ode [A]ction" }
          )
        end,
      })

      -- Bash LSP configuration
      -- requires nix package `bash-language-server` and `shellcheck`
      vim.lsp.enable("bashls")

      -- Clang LSP configuration
      --vim.lsp.enable("clangd")

      -- GO LSP configuration
      vim.lsp.enable("gopls")

      -- Lua LSP configuration
      -- requires nix package `lua-language-server`
      -- requires `lazydev.nvim` plugin to avoid "vim" global errors
      vim.lsp.enable("lua_ls")

      -- Markdown LSP configuration
      -- requires nix package `marksman`
      vim.lsp.enable("marksman")

      -- Nix LSP configuration
      vim.lsp.enable("nixd")

      -- YAML LSP configuration
      -- depends on the yaml LSP being installed via nix
      vim.lsp.enable("yamlls")
    end,
  },
  {
    -- ---------------------------------------------------------------------------------------------
    -- [rustaceanvim](https://github.com/mrcjkb/rustaceanvim)
    -- Ready made Rust LSP configuration to handle all the things
    -- ---------------------------------------------------------------------------------------------
    "rustaceanvim", -- Lua result/pack/nvim-custom/opt/? module name
    lazy = false, -- This plugin is already lazy
    after = function()
      require("rustaceanvim") -- no need to call setup

      -- Custom configuration
      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              buildScripts = { enable = true },
              loadOutDirsFromCheck = true,
            },
            check = {
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
            checkOnSave = true,
            files = {
              excludeDirs = {
                ".direnv",
                ".git",
                "target",
              },
            },
          },
        },
      })

      -- Configure custom highlighting for rust unsafe code blocks
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "rust_analyzer" then
            vim.fn.matchadd("ErrorMsg", "\\<SAFETY\\ze:")
            local error = vim.api.nvim_get_hl(0, { name = "ErrorMsg" })
            vim.api.nvim_set_hl(0, "@lsp.typemod.operator.unsafe.rust", { underline = true, sp = error.fg })
            vim.api.nvim_set_hl(0, "@lsp.typemod.function.unsafe.rust", { underline = true, sp = error.fg })
            vim.api.nvim_set_hl(0, "@lsp.typemod.method.unsafe.rust", { underline = true, sp = error.fg })
          end
        end,
      })
    end,
  },
  {
    "conform.nvim",
    event = "BufWritePre",
    after = function()
      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          nix = { "nixpkgs_fmt", "injected" },
          rust = { "rustfmt" },
          --python = { "black" },
          toml = { "taplo" },
          markdown = { "markdownlint-cli2" },
        },
        format_on_save = function(bufnr)
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          return { timeout_ms = 500, lsp_format = "fallback" }
        end,
      })

      -- FormatDisable! will disable formatting just for this buffer
      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
      end, {
        desc = "Disable autoformat-on-save",
        bang = true,
      })
      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, {
        desc = "Re-enable autoformat-on-save",
      })
    end,
  },
}
