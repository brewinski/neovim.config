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
        adapters = {
          require 'neotest-golang', -- { warn_test_not_executed = false }, -- Registration
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
      {
        '<leader>to',
        function()
          require('neotest').output.open { enter = true }
        end,
        desc = 'Test summary pannel',
      },
      {
        '<leader>',
      },
    },
  },
}
