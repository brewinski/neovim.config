local amp_cli = require 'custom.scripts.amp.amp-cli'

local Thread = {}
Thread.__index = Thread

function Thread.new(id, opts)
  opts = opts or {}
  return setmetatable({ id = id }, Thread)
end

function Thread:on_response(message)
  print(message)
end

function Thread:send(message)
  print('thread send(): ' .. message .. 'id: ' .. self.id)
  amp_cli.amp_message_cmd(message, self.on_response, { thread_id = self.id })
end

return Thread
