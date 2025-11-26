local api = vim.api
local main = require 'amp-ui.main'

local M = {}

function M.toggle()
  main.toggle_ui()
end

function M.dev_reload()
  main.cleanup_ui()
  require('lazy.core.loader').reload 'amp-ui'
end

return M
