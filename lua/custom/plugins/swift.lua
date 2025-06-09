-- Swift development configuration
return {
  'keith/swift.vim',
  ft = 'swift', -- Only load for Swift files
  dependencies = {
    -- LSP configuration for Swift/SourceKit
    'neovim/nvim-lspconfig',
  },
  config = function()
    -- Only configure sourcekit if we're on macOS and have Xcode tools
    if not vim.fn.has 'macunix' == 1 or not vim.fn.executable 'sourcekit-lsp' == 1 then
      return
    end
    -- Set Swift-specific options
    require('lspconfig').sourcekit.setup {}
    -- Configure autocmd to set Swift-specific options
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'swift',
      callback = function()
        -- Set Swift-specific options
        vim.opt_local.expandtab = true
        vim.opt_local.shiftwidth = 4
        vim.opt_local.tabstop = 4

        -- Swift-specific keymaps
        vim.keymap.set('n', '<leader>cb', '<cmd>!swift build<CR>', { buffer = true, desc = '[C]ode Swift [B]uild' })
        vim.keymap.set('n', '<leader>cr', '<cmd>!swift run<CR>', { buffer = true, desc = '[C]ode Swift [R]un' })
        vim.keymap.set('n', '<leader>ct', '<cmd>!swift test<CR>', { buffer = true, desc = '[C]ode Swift [T]est' })
      end,
    })
  end,
}
