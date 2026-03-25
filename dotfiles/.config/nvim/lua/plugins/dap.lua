return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      {
        "mxsdev/nvim-dap-vscode-js",
        dependencies = {
          {
            "microsoft/vscode-js-debug",
            version = "1.x",
            build = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
          },
        },
      },
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: Continue" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Debug: Conditional Breakpoint" },
      { "<leader>dr", function() require("dap").repl.open() end, desc = "Debug: Open REPL" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Debug: Toggle UI" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("dapui").setup()
      require("nvim-dap-virtual-text").setup()

      require("dap-vscode-js").setup({
        debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
        adapters = { "pwa-node", "pwa-chrome", "node-terminal", "pwa-extensionHost" },
      })

      for _, language in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch current file (Node)",
            program = "${file}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            skipFiles = { "<node_internals>/**", "**/node_modules/**" },
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to Node process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            skipFiles = { "<node_internals>/**", "**/node_modules/**" },
          },
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome (localhost:3000)",
            url = "http://localhost:3000",
            webRoot = "${workspaceFolder}",
            sourceMaps = true,
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "React Native: Attach to Metro (8081)",
            cwd = "${workspaceFolder}",
            port = 8081,
            sourceMaps = true,
            skipFiles = { "<node_internals>/**", "**/node_modules/**" },
          },
        }
      end

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
}
