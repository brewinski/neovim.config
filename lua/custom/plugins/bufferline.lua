return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = 'nvim-tree/nvim-web-devicons',
  config = function()
    vim.opt.termguicolors = true
    require('bufferline').setup {
      options = {
        mode = 'buffers', -- set to "tabs" to only show tabpages instead
        diagnostics = 'nvim_lsp',
      },
    }

    vim.api.nvim_set_keymap('n', '<Tab>', '<CMD>BufferLineCycleNext<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<S-Tab>', '<CMD>BufferLineCyclePrev<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<leader>x', '<CMD>confirm bdelete<CR>', { noremap = true, silent = true, desc = 'close the current buffer' })
  end,
}
