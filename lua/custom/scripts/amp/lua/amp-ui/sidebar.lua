local Split = require 'nui.split'
local Input = require 'nui.input'
local event = require('nui.utils.autocmd').event
local api = vim.api

-- TODO: provide this as a user configurable option. merge user values into base values
local base_sidebar_config = {
  ns_id = 'amp_ui',
  relative = 'editor',
  position = 'right',
  size = '30%',
  win_options = {
    winfixbuf = true,
    number = false,
    relativenumber = false,
    winfixwidth = true,
  },
  buf_options = {
    modifiable = false,
    swapfile = false,
  },
}

-- TODO: provide this as a user configurable option. merge user values into base values
local base_input_config = {
  ns_id = 'amp_ui',
  position = '100%',
  size = {
    width = '95%',
    height = '5%',
  },
  border = {
    style = 'single',
    text = {
      top = '[Howdy?]',
      top_align = 'center',
    },
  },
  win_options = {
    winhighlight = 'Normal:Normal,FloatBorder:Normal',
  },
}

local sidebar_keymaps = {
  input = { keys = { 'i' }, mode = 'n' },
}

local Sidebar = {}
Sidebar.__index = Sidebar

local instances = {}

function Sidebar.get_or_create(id)
  if not instances[id] then
    instances[id] = Sidebar:new(id)
  end

  return instances[id]
end

function Sidebar.cleanup_all()
  for _, instance in pairs(instances) do
    instance:destroy()
  end
end

function Sidebar:new(id)
  local instance = setmetatable({
    id = id,
    sidebar = Split(base_sidebar_config),
  }, Sidebar)

  instance.id = id
  instance.sidebar = Split(base_sidebar_config)

  return instance
end

function Sidebar:_set_defaults()
  -- re register keymaps just in case the buffer was deleted e.t.c
  self:set_keymaps()
end

function Sidebar:set_keymaps()
  self.sidebar:map(sidebar_keymaps.input.mode, sidebar_keymaps.input.keys, function()
    local input = Input(base_input_config, {
      prompt = '> ',
      default_value = '',
      on_close = function()
        print 'Input Closed!'
      end,
      on_submit = function(value)
        print('Input Submitted: ' .. value)
      end,
    })

    input:map('n', '<ESC>', function()
      input:unmount()
    end)

    input:on(event.BufLeave, function()
      input:unmount()
    end)

    input:mount()
  end)
end

function Sidebar:toggle()
  if not self.sidebar.winid then
    self:show()
    return
  end

  self:hide()
end

function Sidebar:hide()
  self:_set_defaults()
  self.sidebar:hide()
end

function Sidebar:show()
  self:_set_defaults()
  self.sidebar:show()
end

function Sidebar:destroy()
  self.sidebar:unmount()
end

return Sidebar
