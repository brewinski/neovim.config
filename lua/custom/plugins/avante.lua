local avante_cody = require 'custom.scripts.avante-cody'

return {
  'yetone/avante.nvim',
  -- name = 'yetone/avante.nvim',
  -- dev = true,
  -- dir = '~/Documents/github/avante.nvim',
  event = 'VeryLazy',
  lazy = true,
  version = false, -- set this if you want to always pull the latest change
  opts = {
    -- add any opts here
    provider = 'copilot',
    auto_suggestions_provider = 'copilot',
    copilot = {
      endpoint = 'https://api.githubcopilot.com',
      model = 'claude-3.5-sonnet',
      proxy = nil, -- [protocol://]host[:port] Use this proxy
      allow_insecure = false, -- Allow insecure server connections
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
    },
    behaviour = {
      auto_suggestions = true, -- Experimental stage
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = false,
    },
    mappings = {
      suggestion = {
        accept = '<C-a>',
      },
    },
    repo_map = {
      ignore_patterns = { '%.git', '%.worktree', '__pycache__', 'node_modules', 'providers' }, -- ignore files matching these
    },
    vendors = {
      ['work-cody'] = {
        model = avante_cody.model,
        endpoint = avante_cody.endpoint,
        api_key_name = avante_cody.api_key_name,
        max_tokens = avante_cody.max_tokens,
        stream = false,
        topK = avante_cody.topK,
        topP = avante_cody.topP,
        proxy = avante_cody.proxy,
        allow_insecure = avante_cody.allow_insecure,
        timeout = avante_cody.timeout,
        temperature = avante_cody.temperature,
        parse_curl_args = avante_cody.parse_curl_args,
        parse_response_data = avante_cody.parse_response_data,
      },
      -- endpoint = 'https://sourcegraph.com',
      -- model = 'anthropic::2024-10-22::claude-3-5-sonnet-latest',
      -- timeout = 30000,
      -- temperature = 0,
      -- model = "anthropic::2024-10-22::claude-3-5-sonnet-latest"
      -- model = "anthropic::2024-10-22::claude-3-5-haiku-latest"
      -- model = "anthropic::2023-06-01::claude-3-haiku"
      -- model = "mistral::v1::mixtral-8x7b-instruct"
      -- model = "google::v1::gemini-1.5-flash"
    },
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = 'make',
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'stevearc/dressing.nvim',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    --- The below dependencies are optional,
    'nvim-tree/nvim-web-devicons', -- or echasnovski/mini.icons
    {
      'zbirenbaum/copilot.lua',
      config = function()
        require('copilot').setup {}
      end,
    }, -- for providers='copilot'
    {
      -- support for image pasting
      'HakonHarnes/img-clip.nvim',
      event = 'VeryLazy',
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { 'markdown', 'Avante' },
      },
      ft = { 'markdown', 'Avante' },
    },
  },
}

-- examples
-- local rpc = require("sg.rpc")
--
-- local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
--
-- vim.api.nvim_notify(path .. "\n\n\n\n\n\n\n\n\n\n", 1, {})
--
-- rpc.get_remote_url(
--   path,
--   function(err, remote_url) vim.api.nvim_notify("\nresults: " .. vim.inspect(remote_url), 1, {}) end
-- )
--
-- rpc.get_search("AuthService", function(err, results)
--   -- vim.api.nvim_notify("err: " .. vim.inspect(err) .. "\nresults: " .. vim.inspect(results), 1, {})
-- end)
