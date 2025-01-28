require 'custom.scripts.keymaps'

-- Load quote-service specific configuration
vim.api.nvim_create_autocmd({ 'DirChanged', 'VimEnter' }, {
  pattern = '*',
  callback = function()
    package.loaded['custom.scripts.quote-service'] = nil -- Clear the cache
    require 'custom.scripts.quote-service' -- Reload the module
  end,
})

-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {}
