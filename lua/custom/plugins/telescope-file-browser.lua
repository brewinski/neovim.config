-- keymappings for the file browser plugin
vim.keymap.set('n', '<space>fb', function()
  require('telescope').extensions.file_browser.file_browser()
end)

vim.keymap.set('n', '<space>fd', function()
  require('telescope').extensions.file_browser.file_browser {
    path = vim.fn.expand '%:p:h',
  }
end)

return {
  'nvim-telescope/telescope-file-browser.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
}
