return {
  'brewinski/amp-ui',
  dir = '~/.config/nvim/lua/custom/scripts/amp',
  dev = true,
  lazy = true,
  -- opts = {},
  keys = {
    {
      '<leader>mm',
      function()
        require('amp-ui').toggle()
      end,
      desc = 'load the amp ui',
    },
    {
      '<leader>mr',
      function()
        require('amp-ui').dev_reload()
      end,
      desc = 'reload the plugin',
    },
  },
}
