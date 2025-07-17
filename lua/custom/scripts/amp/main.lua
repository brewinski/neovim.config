local api = vim.api
local amp_cli = require 'custom.scripts.amp.amp-cli'
local Thread = require 'custom.scripts.amp.thread'

local M = {}

local threads = {}
local current_thread = nil

M.autocmds = function()
  api.nvim_create_user_command('AmpVersion', function()
    amp_cli.amp_version_cmd()
  end, {})

  api.nvim_create_user_command('AmpThreads', function()
    amp_cli.amp_threads_cmd()
  end, {})

  api.nvim_create_user_command('AmpMessage', function(opts)
    if current_thread == nil then
      return
    end

    print('Message: ' .. opts.args)

    current_thread:send 'hello!'
  end, {})

  api.nvim_create_user_command('AmpThreadsNew', function()
    amp_cli.amp_threads_new(function(thread_id)
      print('new thread' .. thread_id)
      table.insert(threads, Thread.new(thread_id))
      current_thread = threads[#threads]
    end)
  end, {})
end

M.setup = function(opts)
  M.autocmds()
end

return M
