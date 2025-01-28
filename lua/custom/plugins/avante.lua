local avante_cody = require 'custom.scripts.avante-cody'

return {
  'yetone/avante.nvim',
  dev = true,
  dir = '~/Documents/github/avante.nvim',
  event = 'VeryLazy',
  lazy = true,
  version = false, -- set this if you want to always pull the latest change
  opts = {
    -- add any opts here
    provider = 'work-cody',
    auto_suggestions_provider = 'work-cody',
    copilot = {
      endpoint = 'https://api.githubcopilot.com',
      model = 'claude-3.5-sonnet',
      proxy = nil, -- [protocol://]host[:port] Use this proxy
      allow_insecure = false, -- Allow insecure server connections
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 4096,
    },
    behaviour = {
      auto_suggestions = false, -- Experimental stage
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
      ignore_patterns = { '%.git', '%.worktree', '__pycache__', 'node_modules', 'providers', 'vendor' }, -- ignore files matching these
    },
    file_selector = {
      provider = 'telescope',
      -- Options override for custom providers
      provider_opts = {
        previewer = require('telescope.config').values.file_previewer {},
      },
    },
    vendors = {
      ['work-cody'] = {
        model = 'anthropic::2024-10-22::claude-3-5-sonnet-latest',
        endpoint = 'https://canstar.sourcegraphcloud.com',
        api_key_name = 'cmd:op read --account canstar.1password.com op://Employee/sourcegraph_apikey/credential',
        max_tokens = 15000,
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
      ['cody'] = {
        model = 'anthropic::2024-10-22::claude-3-5-sonnet-latest',
        endpoint = 'https://sourcegraph.com',
        api_key_name = 'cmd:op read --account my.1password.com op://Developer/sourcegraph_apikey/credential',
        max_tokens = avante_cody.max_output_tokens,
        topK = avante_cody.topK,
        topP = avante_cody.topP,
        proxy = avante_cody.proxy,
        allow_insecure = avante_cody.allow_insecure,
        timeout = avante_cody.timeout,
        temperature = avante_cody.temperature,
        parse_curl_args = avante_cody.parse_curl_args,
        parse_response_data = avante_cody.parse_response_data,
      },
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
