local function extend_unique(list, items)
  local seen = {}
  for _, v in ipairs(list) do
    seen[v] = true
  end
  for _, v in ipairs(items) do
    if not seen[v] then
      table.insert(list, v)
      seen[v] = true
    end
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      extend_unique(opts.ensure_installed, {
        "bash",
        "css",
        "dockerfile",
        "gitignore",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "markdown",
        "markdown_inline",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      })
    end,
  },

  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      extend_unique(opts.ensure_installed, {
        "css-lsp",
        "emmet-language-server",
        "eslint_d",
        "eslint-lsp",
        "html-lsp",
        "js-debug-adapter",
        "json-lsp",
        "prettierd",
        "tailwindcss-language-server",
        "vtsls",
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      opts.servers.vtsls = {
        filetypes = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
        },
        settings = {
          complete_function_calls = true,
          vtsls = {
            enableMoveToFileCodeAction = true,
            autoUseWorkspaceTsdk = true,
          },
          typescript = {
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = false },
            },
            preferences = {
              importModuleSpecifier = "non-relative",
            },
          },
          javascript = {
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = false },
            },
          },
        },
      }

      opts.servers.eslint = {
        settings = {
          workingDirectories = { mode = "auto" },
        },
      }

      opts.servers.tailwindcss = {}
      opts.servers.html = {}
      opts.servers.cssls = {}
      opts.servers.jsonls = {}
      opts.servers.emmet_language_server = {
        filetypes = {
          "css",
          "eruby",
          "html",
          "javascriptreact",
          "less",
          "sass",
          "scss",
          "typescriptreact",
        },
      }

      opts.setup = opts.setup or {}
      opts.setup.vtsls = function(_, server_opts)
        local on_attach = server_opts.on_attach
        server_opts.on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
          if on_attach then
            on_attach(client, bufnr)
          end
        end
      end
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.javascript = { "prettierd", "prettier", stop_after_first = true }
      opts.formatters_by_ft.javascriptreact = { "prettierd", "prettier", stop_after_first = true }
      opts.formatters_by_ft.typescript = { "prettierd", "prettier", stop_after_first = true }
      opts.formatters_by_ft.typescriptreact = { "prettierd", "prettier", stop_after_first = true }
      opts.formatters_by_ft.css = { "prettierd", "prettier", stop_after_first = true }
      opts.formatters_by_ft.scss = { "prettierd", "prettier", stop_after_first = true }
      opts.formatters_by_ft.html = { "prettierd", "prettier", stop_after_first = true }
      opts.formatters_by_ft.json = { "prettierd", "prettier", stop_after_first = true }
      opts.formatters_by_ft.jsonc = { "prettierd", "prettier", stop_after_first = true }
      opts.formatters_by_ft.yaml = { "prettierd", "prettier", stop_after_first = true }
      opts.formatters_by_ft.markdown = { "prettierd", "prettier", stop_after_first = true }
      opts.format_on_save = { timeout_ms = 2000, lsp_format = "fallback" }
    end,
  },

  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.javascript = { "eslint_d" }
      opts.linters_by_ft.javascriptreact = { "eslint_d" }
      opts.linters_by_ft.typescript = { "eslint_d" }
      opts.linters_by_ft.typescriptreact = { "eslint_d" }
    end,
  },

  {
    "vuki656/package-info.nvim",
    ft = { "json" },
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      hide_up_to_date = true,
    },
    config = function(_, opts)
      require("package-info").setup(opts)
    end,
  },
}
