local M = {}

M.avante = {
  'yetone/avante.nvim',
  event = 'VeryLazy',
  version = false, -- Never set this value to "*"! Never!
  opts = {
    -- add any opts here
    -- for example
    provider = 'copilot',
    -- openai = {
    --   endpoint = "https://api.openai.com/v1",
    --   model = "gpt-4o", -- your desired model (or use gpt-4o, etc.)
    --   timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
    --   temperature = 0,
    --   max_completion_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
    --   --reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
    -- },

    mappings = {
      files = {
        add_current = '<leader>ab',
      },
    },
  },

  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = 'make',

  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'zbirenbaum/copilot.lua', -- for providers='copilot'
  },
}

M.copilot = {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = { 'InsertEnter' },
  config = function()
    require('copilot').setup {
      filetypes = {
        markdown = true, -- overrides default
      },
      suggestion = {
        hide_during_completion = false,
        auto_trigger = true,
      },
      copilot_node_command = 'node', -- Node.js version must be > 18.x
    }
  end,
}

return {
  M.copilot,
  M.avante,
}
