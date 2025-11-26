local Sidebar = require 'amp-ui.sidebar'
local acp = require 'amp-ui.acp-client'

local M = {
  default_sidebar = Sidebar.get_or_create 'default_sidebar',
}

function M.toggle_ui()
  acp.start()
  M.default_sidebar:toggle()
end

function M.cleanup_ui()
  Sidebar.cleanup_all()
end

return M
