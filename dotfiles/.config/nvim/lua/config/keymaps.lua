-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

local function root_dir()
  local markers = {
    "package.json",
    "pnpm-lock.yaml",
    "yarn.lock",
    "bun.lockb",
    "bun.lock",
    ".git",
  }
  return vim.fs.root(0, markers) or vim.uv.cwd()
end

local function package_manager(dir)
  if vim.uv.fs_stat(dir .. "/pnpm-lock.yaml") then
    return "pnpm"
  end
  if vim.uv.fs_stat(dir .. "/yarn.lock") then
    return "yarn"
  end
  if vim.uv.fs_stat(dir .. "/bun.lockb") or vim.uv.fs_stat(dir .. "/bun.lock") then
    return "bun"
  end
  return "npm"
end

local function run_in_terminal(cmd)
  vim.cmd("botright 14split")
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
end

local function run_script(script, extra_args)
  local dir = root_dir()
  local pm = package_manager(dir)
  local args = extra_args or ""

  local command
  if pm == "pnpm" then
    command = "cd " .. vim.fn.fnameescape(dir) .. " && pnpm " .. script .. (args ~= "" and (" " .. args) or "")
  elseif pm == "yarn" then
    command = "cd " .. vim.fn.fnameescape(dir) .. " && yarn " .. script .. (args ~= "" and (" " .. args) or "")
  elseif pm == "bun" then
    command = "cd " .. vim.fn.fnameescape(dir) .. " && bun run " .. script .. (args ~= "" and (" " .. args) or "")
  else
    command = "cd " .. vim.fn.fnameescape(dir) .. " && npm run " .. script .. (args ~= "" and (" -- " .. args) or "")
  end

  run_in_terminal(command)
end

local function current_file_from_root()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return nil
  end
  return vim.fn.fnamemodify(file, ":.")
end

-- Run scripts (web + React Native)
map("n", "<leader>rd", function()
  run_script("dev")
end, { desc = "Run: dev server" })

map("n", "<leader>rb", function()
  run_script("build")
end, { desc = "Run: build" })

map("n", "<leader>rt", function()
  run_script("test")
end, { desc = "Run: tests" })

map("n", "<leader>rT", function()
  local rel_file = current_file_from_root()
  if not rel_file then
    vim.notify("Nenhum arquivo atual para testar.", vim.log.levels.WARN)
    return
  end
  run_script("test", rel_file)
end, { desc = "Run: test current file" })

map("n", "<leader>rn", function()
  run_script("start")
end, { desc = "React Native: start/metro" })

map("n", "<leader>ra", function()
  run_in_terminal("cd " .. vim.fn.fnameescape(root_dir()) .. " && npx react-native run-android")
end, { desc = "React Native: run Android" })

map("n", "<leader>ri", function()
  run_in_terminal("cd " .. vim.fn.fnameescape(root_dir()) .. " && npx react-native run-ios")
end, { desc = "React Native: run iOS" })

-- Refactor/LSP
map("n", "<leader>cR", vim.lsp.buf.rename, { desc = "Refactor: rename symbol" })

map({ "n", "v" }, "<leader>cA", vim.lsp.buf.code_action, { desc = "Refactor: code actions" })

map("n", "<leader>co", function()
  vim.lsp.buf.code_action({
    apply = true,
    context = { only = { "source.organizeImports" }, diagnostics = {} },
  })
end, { desc = "Refactor: organize imports" })

map("n", "<leader>cu", function()
  vim.lsp.buf.code_action({
    apply = true,
    context = { only = { "source.removeUnused" }, diagnostics = {} },
  })
end, { desc = "Refactor: remove unused" })

-- Navigation helpers
map("n", "]e", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "[e", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
