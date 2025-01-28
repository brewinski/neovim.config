local api = vim.api
local Job = require 'plenary.job'
local fidget = require 'fidget'
local progress = require 'fidget.progress'

local Config = {
  notifications = {
    std_out = false,
    std_err = false,
  },
}

-- {
--     ExpectNoLint = false,
--     ExpectedNoLintLinter = "",
--     fromlinter = "errcheck",
--     Pos = {
--       Column = 31,
--       Filename = "internal/http/server/server.go",
--       Line = 82,
--       Offset = 2210
--     },
--     Replacement = vim.NIL,
--     Severity = "",
--     SourceLines = { "\t\twebhookHandler.MountHandlers(r)" },
--     Text = "Error return value of `webhookHandler.MountHandlers` is not checked"
--   }

---@class GolangCILintPos
---@field Filename string
---@field Line number
---@field Column number
---@field Offset number
--
---@class GolangCILintIssue
---@field ExpectNoLint boolean
---@field FromLinter string
---@field Text string
---@field Pos GolangCILintPos
---@field SourceLines string[]
---
---@class GolangCILintOutput
---@field Issues GolangCILintIssue[]
---
---{
--   Action = "output",
--   Output = "--- PASS: Test_GetQuotesEndpoint_Race/Race_Test:_2 (0.02s)\n",
--   Package = "bitbucket.org/canstar-dev/quote-service/internal/http/server",
--   Test = "Test_GetQuotesEndpoint_Race/Race_Test:_2",
--   Time = "2025-01-13T15:45:24.839858+10:00"
-- }
--
---@class GoTestOutput
---@field Action string
---@field Output string
---@field Package string
---@field Test string
---@field Time string

local FIDGET_NOTIFICATION_GROUP = 'quote-service'

local AU_GROUP = api.nvim_create_augroup('quote-service-commands', { clear = true })

local LINTER_ISSUE_NAMESPACE = api.nvim_create_namespace 'quote-service-lint'
---@type GolangCILintIssue[]
local LINTER_ISSUES = {}
local LINTER_HINT_ERROR = 'quote-service-lint-hint-error'

vim.api.nvim_set_hl(0, LINTER_HINT_ERROR, { fg = '#cc0000', bg = '#000000' })

local LINTER_NOTIFICATION_GROUP = 'golangci-lint'

local TEST_NOTIFICATION_GROUP = 'go test'
local TEST_RESULTS = {}

local QS_NOTIFICATION_GROUP = 'quote-service'

---comment
---@param bufnr number
local function clear_linter_virt_txt(bufnr)
  api.nvim_buf_clear_namespace(bufnr, LINTER_ISSUE_NAMESPACE, 0, -1)
end

---@param bufnr number
---@param file string
---@param issue GolangCILintIssue
local function issue_is_in_buffer_and_line_matches(bufnr, file, issue)
  if not file:match(issue.Pos.Filename) then
    return false
  end

  local lines_at_issue = api.nvim_buf_get_lines(bufnr, issue.Pos.Line - 1, issue.Pos.Line, false)
  if lines_at_issue[1] ~= issue.SourceLines[1] then
    return false
  end

  return true
end

---set linter issues for all provided buffers
---@param bufnr number
---@param file string
---@param issues GolangCILintIssue[]
local function set_linter_virt_txt(bufnr, file, issues)
  clear_linter_virt_txt(bufnr)

  for _, issue in ipairs(issues) do
    if issue_is_in_buffer_and_line_matches(bufnr, file, issue) then
      api.nvim_buf_set_extmark(bufnr, LINTER_ISSUE_NAMESPACE, issue.Pos.Line - 1, -1, {
        virt_text = {
          {
            issue.FromLinter .. ': ' .. issue.Text,
            LINTER_HINT_ERROR,
          },
        },
      })
    end
  end
end

---
---@param issues GolangCILintIssue[]
local function populate_linter_qf_list(issues)
  if #issues <= 0 then
    vim.notify('no linter issues detected', vim.log.levels.INFO, {})
    return
  end

  local files = {}
  for _, issue in ipairs(issues) do
    table.insert(files, { filename = issue.Pos.Filename, lnum = issue.Pos.Line, col = issue.Pos.Column })
  end

  vim.fn.setqflist(files)
  vim.cmd.copen()
end

local function set_linter_virt_txt_open_bufs()
  local buffers = api.nvim_list_bufs()

  for _, bufnr in ipairs(buffers) do
    local file = api.nvim_buf_get_name(bufnr)
    set_linter_virt_txt(bufnr, file, LINTER_ISSUES)
  end
end

local function run_golang_ci_lint()
  local handle = progress.handle.create {
    key = LINTER_NOTIFICATION_GROUP,
    lsp_client = { name = LINTER_NOTIFICATION_GROUP },
    token = LINTER_NOTIFICATION_GROUP,
    message = '',
  }

  Job:new({
    command = 'golangci-lint',
    args = {
      'run',
      './...',
      '--timeout',
      '3m',
      '-v',
      '--exclude-dirs',
      'tooling',
      '--exclude-dirs',
      'pkg/test',
      '--out-format',
      'json',
    },
    on_exit = function(job)
      local result = table.concat(job:result(), '\n')
      ---@type GolangCILintOutput
      local response = vim.json.decode(result)

      if not response or not response.Issues or #response.Issues <= 0 then
        LINTER_ISSUES = {}
      else
        LINTER_ISSUES = response.Issues
        handle:report {
          message = 'FAIL [<leader>cq: view]',
        }
      end

      vim.schedule(function()
        set_linter_virt_txt_open_bufs()
      end)

      handle:finish()
    end,
    on_stdout = function(_, data)
      if Config.notifications.std_out then
        handle:report { message = data }
      end
    end,
    on_stderr = function(_, data)
      if Config.notifications.std_err then
        handle:report { message = data }
      end
    end,
  }):start()
end

local function run_go_test()
  local handle = progress.handle.create {
    key = TEST_NOTIFICATION_GROUP,
    lsp_client = { name = TEST_NOTIFICATION_GROUP },
    token = TEST_NOTIFICATION_GROUP,
    message = '',
  }

  Job:new({
    command = 'go',
    args = {
      'test',
      './...',
      '-race',
      '-json',
    },
    on_exit = function(job, code, sig)
      local result = table.concat(job:result(), '\n')
      ---@type GoTestOutput[]
      local response = vim.json.decode('[' .. table.concat(vim.split(result, '\n'), ',') .. ']')

      for _, test in ipairs(response) do
        if test.Action == 'fail' and test.Test ~= nil then
          vim.print(vim.inspect(test))
          handle:report { message = test.Action .. ' ' .. test.Test .. ' ', test.Output }
        end
      end

      handle:finish()
    end,
    -- on_stdout = function(err, data)
    -- 	handle:report({ message = data })
    -- end,
    -- on_stderr = function(_, data)
    -- 	handle:report({ message = data })
    -- end,
  }):start()
end

local function stop_quote_service()
  local _handle = io.popen 'kill $(lsof -t -i:8091)'
  if _handle ~= nil then
    _handle:close()
  end
end

local function start_quote_service()
  local handle = progress.handle.create {
    key = QS_NOTIFICATION_GROUP,
    lsp_client = { name = QS_NOTIFICATION_GROUP },
    token = QS_NOTIFICATION_GROUP,
    message = 'Listening on port 8091',
  }

  local job = Job:new {
    cwd = './cmd/quoteapi',
    command = 'go',
    args = {
      'run',
      '.',
    },
    on_exit = function(job, code, sig)
      -- local result = table.concat(job:result(), "\n")

      vim.schedule(function()
        handle:report { message = 'Restarting server' }
        handle:finish()
      end)
    end,
    -- on_stdout = function(_, data)
    -- 	vim.schedule(function()
    -- 		handle:report({
    -- 			message = data,
    -- 		})
    -- 	end)
    -- end,
    -- on_stderr = function(_, data)
    -- 	vim.schedule(function()
    -- 		handle:report({ message = data })
    -- 	end)
    -- end,
  }

  job:start()
end

local function setup_keymappings()
  vim.keymap.set('n', '<leader>cq', function()
    populate_linter_qf_list(LINTER_ISSUES)
  end, {})
end

local function debounce(ms, fn)
  local timer = vim.loop.new_timer()
  return function(...)
    local argv = { ... }
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule_wrap(fn)(unpack(argv))
    end)
  end
end

local debounce_go_test_fn = debounce(1000, run_go_test)
local debounce_golangci_lint_fn = debounce(1000, run_golang_ci_lint)
local debounce_quote_serice_fn = debounce(1000, start_quote_service)
local debounce_stop_quote_service_fn = debounce(1, stop_quote_service)

local function setup_autocmds()
  -- ensure quote service is killed when vim exits or crashes
  api.nvim_create_autocmd({ 'VimLeavePre' }, {
    group = AU_GROUP,
    callback = function()
      stop_quote_service()
    end,
  })
  -- whenever a file is read or written to, run the commands
  api.nvim_create_autocmd({ 'BufWrite' }, {
    pattern = '*.go',
    group = AU_GROUP,
    callback = function()
      debounce_golangci_lint_fn()
      debounce_go_test_fn()

      debounce_stop_quote_service_fn()
      debounce_quote_serice_fn()
    end,
  })

  -- whenever a buffer is entered, check the linter issues and set the virtual text
  api.nvim_create_autocmd({ 'BufRead' }, {
    pattern = '*.go',
    group = AU_GROUP,
    callback = function(ev)
      set_linter_virt_txt(ev.buf, ev.file, LINTER_ISSUES)
    end,
  })

  api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    pattern = '*.go',
    group = AU_GROUP,
    callback = function(ev)
      set_linter_virt_txt(ev.buf, ev.file, LINTER_ISSUES)
    end,
  })
end

local function setup()
  -- setup autocmds
  setup_autocmds()
  setup_keymappings()

  -- populate initial issue state
  debounce_golangci_lint_fn()
  debounce_go_test_fn()

  debounce_quote_serice_fn()

  fidget.notify('configured developer commands...', vim.log.levels.DEBUG, {
    annote = FIDGET_NOTIFICATION_GROUP,
    group = FIDGET_NOTIFICATION_GROUP,
    key = FIDGET_NOTIFICATION_GROUP,
    skip_history = true,
  })
end

-- Check if we're in the quote-service repository
local function is_quote_service_repo()
  local current_dir = vim.fn.getcwd()
  local git_dir = current_dir .. '/.git'

  if vim.fn.isdirectory(git_dir) == 1 then
    local cmd = string.format('git -C %s config --get remote.origin.url', vim.fn.shellescape(current_dir))
    local handle = io.popen(cmd)
    if handle then
      local result = handle:read '*a'
      handle:close()
      -- Adjust this pattern to match your repository URL
      return result:match 'quote%-service' ~= nil
    end
  end
  return false
end

-- Only proceed if we're in the quote-service repository
if is_quote_service_repo() then
  setup()
end
