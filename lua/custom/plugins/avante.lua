return {
  'yetone/avante.nvim',
  dev = true,
  dir = '~/Documents/github/avante.nvim',
  event = 'VeryLazy',
  lazy = true,
  version = false, -- set this if you want to always pull the latest change
  opts = {
    mode = 'legacy',
    -- add any opts here
    provider = 'sg-claude-4',
    auto_suggestions_provider = 'sg-claude-4',
    providers = {
      copilot = {
        extra_request_body = {
          temperature = 0,
          max_tokens = 4096,
        },
        endpoint = 'https://api.githubcopilot.com',
        model = 'claude-3.5-sonnet',
        proxy = nil, -- [protocol://]host[:port] Use this proxy
        allow_insecure = false, -- Allow insecure server connections
        timeout = 30000, -- Timeout in milliseconds
      },
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
        next = '<C-s>',
        prev = '<C-S>',
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
    disabled_tools = { 'insert', 'create', 'str_replace', 'replace_in_file', 'python' },
    -- system_prompt as function ensures LLM always has latest MCP server state
    -- This is evaluated for every message, even in existing chats
    -- system_prompt = function()
    --   local hub = require('mcphub').get_hub_instance()
    --   return hub and hub:get_active_servers_prompt() or ''
    -- end,
    -- -- Using function prevents requiring mcphub before it's loaded
    -- custom_tools = function()
    --   return {
    --     require('mcphub.extensions.avante').mcp_tool(),
    --   }
    -- end,
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
    {
      'brewinski/avante-cody.nvim',
      dev = true,
      dir = '~/Documents/github/avante-cody.nvim',
      opts = {
        debug = true,
        logfile = 'avante-cody.nvim.log',
        override = {
          avante_llm_summarize_chat_thread = false,
          avante_llm_summarize_memory = false,
        },
        providers = {
          ['sg-claude-4'] = {
            model = 'anthropic::2024-10-22::claude-sonnet-4-latest',
            endpoint = 'https://canstar.sourcegraphcloud.com',
            api_key_name = 'cmd:op read --account canstar.1password.com op://Employee/sourcegraph_apikey/credential',
          },
          ['sg-claude-3.5'] = {
            model = 'anthropic::2024-10-22::claude-3-5-sonnet-latest',
            endpoint = 'https://canstar.sourcegraphcloud.com',
            api_key_name = 'cmd:op read --account canstar.1password.com op://Employee/sourcegraph_apikey/credential',
          },
          ['cody-claude-3.7'] = {
            endpoint = 'https://canstar.sourcegraphcloud.com',
            api_key_name = 'cmd:op read --account canstar.1password.com op://Employee/sourcegraph_apikey/credential',
          },
          ['cody/chrisandemma'] = {
            api_key_name = 'SG_API_KEY',
          },
          ['cody-claude-3.7-extended-thinking'] = {
            model = 'anthropic::2024-10-22::claude-3-7-sonnet-extended-thinking',
            endpoint = 'https://canstar.sourcegraphcloud.com',
            api_key_name = 'cmd:op read --account canstar.1password.com op://Employee/sourcegraph_apikey/credential',
          },
        },
      },
    },
  },
}
