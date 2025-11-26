local initialize = {
  jsonrpc = '2.0',
  id = 0,
  method = 'initialize',
  params = {
    protocolVersion = 1,
    clientCapabilities = {
      fs = {
        readTextFile = false,
        writeTextFile = false,
      },
      terminal = false,
    },
  },
  clientInfo = {
    name = 'brewinski-amp',
    title = 'Brewinski ACP',
    version = '1.0.0',
  },
}

local session_new = {
  jsonrpc = 2.0,
  id = 1,
  method = 'session/new',
  params = {
    cwd = '/home/user/project',
    mcpServers = {
      {
        name = 'filesystem',
        command = '/path/to/mcp-server',
        args = { '--stdio' },
        env = {},
      },
    },
  },
}

local Client = {}
Client.__index = Client

function Client:new(opts)
  opts = opts or {}
  local instance = setmetatable({}, Client)

  instance.stdout = vim.uv.new_pipe(false)
  instance.stdin = vim.uv.new_pipe(false)
  instance.stderr = vim.uv.new_pipe(false)

  instance.cmd = opts.cmd or '/opt/homebrew/bin/opencode'
  instance.args = opts.args or { 'acp' }
  instance.msg_callbacks = {}
  instance.err_callbacks = {}

  return instance
end

function Client:start()
  local handle, pid = vim.uv.spawn(self.cmd, {
    args = self.args,
    stdio = { self.stdin, self.stdout, self.stderr },
  }, function(code, signal)
    print('Process exited:', code, signal)
    self:stop()
  end)

  self.handle = handle
  self.pid = pid

  -- read output asynchronously
  self.stdout:read_start(function(err, data)
    self:message_callback(err, data)
  end)

  -- read error output asynchronously
  self.stderr:read_start(function(err, data)
    self:error_callback(err, data)
  end)
end

function Client:error_callback(err, data)
  for _, callback in pairs(self.err_callbacks) do
    callback(err, data)
  end
end

function Client:message_callback(err, data)
  if err then
    self:error_callback(err, data)
  end
  if data then
    local json = vim.json.decode(data)
    for _, callback in pairs(self.msg_callbacks) do
      callback(json)
    end
  end
end

function Client:on_message(callback)
  table.insert(self.msg_callbacks, callback)
end

function Client:on_error(callback)
  table.insert(self.err_callbacks, callback)
end

function Client:send(message)
  self.stdin:write(message .. '\n')
end

function Client:stop()
  vim.uv.shutdown(self.stdin, function(err)
    assert(not err, err)
    vim.uv.close(self.handle, function(err)
      assert(not err, err)
      print('uv handle closed', self.handle, self.pid)
    end)
  end)
end

local M = {
  client = Client:new(),
}

function M.start()
  local init_msg = vim.json.encode(initialize)

  M.client:on_message(function(data)
    vim.print('registered message callback ' .. ' data: ' .. vim.inspect(data))
  end)

  M.client:on_error(function(err, data)
    vim.print('registered error callback ' .. vim.inspect(err) .. ' data: ' .. vim.inspect(data))
  end)

  M.client:start()
  M.client:send(init_msg)
end

return M
