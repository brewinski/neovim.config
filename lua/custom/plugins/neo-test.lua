return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      {
        'fredrikaverpil/neotest-golang', -- Installation
        dependencies = {
          'leoluz/nvim-dap-go',
        },
      },
    },
    config = function()
      require('neotest').setup {
        log_level = vim.log.levels.INFO,
        adapters = {
          require 'neotest-golang' {},
        },
      }
    end,
    keys = {
      {
        '<leader>td',
        function()
          require('neotest').run.run { suite = false, strategy = 'dap' }
        end,
        desc = 'Debug nearest test',
      },
      {
        '<leader>tp',
        function()
          require('neotest').summary.toggle()
        end,
        desc = 'Test summary pannel',
      },
    },
  },
}
