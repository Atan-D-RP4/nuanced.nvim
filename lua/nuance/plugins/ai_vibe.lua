local M = {}

M.augment = {
  'augmentcode/augment.vim',
  event = 'VeryLazy',
  config = function()
    vim.g.augment_workspace_folders = { '/path/to/project', '~/another-project' }
  end,
}

X = 912 / 2

M.avante = {
  'yetone/avante.nvim',
  event = 'VeryLazy',
  version = false, -- Never set this value to "*"! Never!
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  build = 'make',

  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-lua/plenary.nvim',
    -- 'MunifTanjim/nui.nvim',
    'zbirenbaum/copilot.lua', -- for providers='copilot'
  },

  ---@module 'avante'
  ---@type avante.Config
  opts = {

    mappings = {
      files = { add_current = '<leader>ab' },
    },
    -- add any opts here
    -- for example
    provider = 'copilot',
    providers = {
      openrouter = {
        __inherited_from = 'openai',
        api_key_name = 'OPENROUTER_API_KEY',
        endpoint = 'https://openrouter.ai/api/v1',
        disable_tools = true, -- disable tools!
        model = 'deepseek/deepseek-r1-0528-qwen3-8b:free', -- your desired model (or use gpt-4o, etc.)
        extra_request_body = {
          timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
          temperature = 0.75,
          max_completion_tokens = 8192 / 2, -- Increase this to include reasoning tokens (for reasoning models)
          reasoning_effort = 'medium', -- low|medium|high, only used for reasoning models
        },
      },
    },
  },
}

M.copilot = {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = { 'InsertEnter' },

  ---@type CopilotConfig
  opts = {
    filetypes = { markdown = true }, -- overrides default
    copilot_node_command = 'node', -- Node.js version must be > 18.x
    copilot_model = 'claude-sonnet-4', -- Select preferred copilot model

    suggestion = {
      hide_during_completion = false,
      auto_trigger = true,
    },

    workspace_folders = {
      vim.fn.expand '~' .. '/Develop/repos/',
      vim.fn.expand '~' .. '/Notes/',
    },
  },
  --
  -- config = function(_, _)
  --   vim.api.nvim_create_autocmd('User', {
  --     pattern = 'BlinkCmpMenuOpen',
  --     callback = function()
  --       vim.b.copilot_suggestion_hidden = true
  --     end,
  --   })
  --
  --   vim.api.nvim_create_autocmd('User', {
  --     pattern = 'BlinkCmpMenuClose',
  --     callback = function()
  --       vim.b.copilot_suggestion_hidden = false
  --     end,
  --   })
  -- end,
}

return {
  M.copilot,
  M.avante,
  -- M.augment
}
