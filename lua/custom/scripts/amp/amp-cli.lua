local M = {}

local amp_cmd = 'amp'
local amp_threads = 'threads'
local amp_threads_list = 'list'
local amp_version = '--version'

M.amp_threads_new = function(on_new_thread)
  vim.fn.jobstart({ amp_cmd, amp_threads, 'new' }, {
    on_stdout = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= '' then
          on_new_thread(line)
        end
      end
    end,
  })
end

M.amp_message_cmd = function(message, on_response, opts)
  local thread_id_cmd = ''

  if opts.thread_id then
    thread_id_cmd = ' --thread ' .. opts.thread_id
  end

  vim.fn.jobstart({ 'sh', '-c', 'echo "' .. message .. '" | amp --format jsonl' .. thread_id_cmd }, {
    on_stdout = function(_, data, _)
      print('cli message cmd: ' .. vim.inspect(data))
      for _, line in ipairs(data) do
        if line ~= '' then
          on_response(line)
        end
      end
    end,
  })
end

M.amp_version_cmd = function()
  vim.fn.jobstart({ amp_cmd, amp_version }, {
    on_stdout = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= '' then
          print(line)
        end
      end
    end,
  })
end

M.amp_threads_cmd = function()
  vim.fn.jobstart({ amp_cmd, amp_threads, amp_threads_list }, {
    on_stdout = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= '' then
          print(line)
        end
      end
    end,
    on_stderr = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= '' then
          print(line)
        end
      end
    end,
    on_exit = function()
      print 'Done'
    end,
  })
end

return M
