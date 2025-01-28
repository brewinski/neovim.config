local api = vim.api

api.nvim_create_autocmd('FileType', {
  pattern = { 'lua' },
  callback = function()
    vim.schedule(function()
      vim.keymap.set('n', '<leader><leader>z', '<CMD>source %<CR>', { buffer = true })
    end)
  end,
})
