local M = {}

M.copilot = {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = { 'InsertEnter' },

  ---@module 'copilot'
  ---@type CopilotConfig
  opts = {
    filetypes = { markdown = true }, -- overrides default
    copilot_model = 'gpt-41-copilot', -- Select preferred copilot model

    suggestion = {
      hide_during_completion = false,
      auto_trigger = true,
    },

    workspace_folders = {
      vim.fn.expand '~' .. '/Develop/repos/',
      vim.fn.expand '~' .. '/Notes/',
    },

    server = { type = 'binary' },
  },
}

M.opencode = {
  'sudo-tee/opencode.nvim',
  event = 'UIEnter',

  config = function()
    require('opencode').setup {
      ui = {
        position = 'current',
        input = { text = { wrap = true } },
      },

      context = {
        enabled = false,
        current_file = { enabled = false },
        diagnostics = {
          info = false, -- Include diagnostics info in the context (default to false)
          warn = false, -- Include diagnostics warnings in the context
          error = false, -- Include diagnostics errors in the context
        },
      },

      keymap = {
        input_window = {
          ['<esc>'] = {},
          ['q'] = { 'close' },
        },

        output_window = {
          ['<esc>'] = {},
          ['q'] = { 'close' },
        },
      },
    }
  end,

  dependencies = {
    'nvim-lua/plenary.nvim',

    {
      'MeanderingProgrammer/render-markdown.nvim',
      ft = { 'markdown', 'Avante', 'copilot-chat', 'opencode_output' },

      opts = {
        enabled = false,
        anti_conceal = { enabled = false },
        file_types = { 'markdown', 'opencode_output' },
      },
    },
  },
}

return {
  M.copilot,
  M.opencode,
}
