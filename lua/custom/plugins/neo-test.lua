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
        version = '*',
      },
      -- 'nvim-neotest/neotest-go',
    },
    config = function()
      require('neotest').setup {
        log_level = vim.log.levels.INFO,
        adapters = {
          require 'neotest-golang' {},
          -- require 'neotest-go',
        },
      }
    end,
    keys = {
      -- {
      --   '<leader><leader>tf',
      --   function()
      --     require('neotest').run.run(vim.fn.expand '%')
      --   end,
      -- },
      {
        '<leader><leader>tn',
        function()
          require('neotest').run.run { suite = false, strategy = 'dap' }
        end,
        desc = 'Debug nearest test',
      },
      {
        '<leader><leader>tp',
        function()
          require('neotest').summary.toggle()
        end,
        desc = 'Test summary pannel',
      },
    },
  },
}
