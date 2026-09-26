local M = {}

M.copilot = {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = { 'InsertEnter' },
  config = function(_, opts)
    require('copilot').setup(opts)
    vim.defer_fn(function()
      -- require('copilot.model').set { args = '', force = true, model = 'oswe-vscode-prime' }
      require('copilot.model').set { args = '', force = true, model = 'opencode/muse-spark-1.3-contributor-free' }
    end, 1000)
  end,

  ---@module 'copilot'
  ---@type CopilotConfig
  opts = {
    filetypes = { markdown = true }, -- overrides default

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
      server = {
        url = 'localhost',
        port = 4096,
        timeout = 5,
      },

      ui = {
        output = {
          tools = {
            show_output = true, -- Show tools output [diffs, cmd output, etc.] (default: true)
            show_reasoning_output = true, -- Show reasoning/thinking steps output (default: true)
          },
        },
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

      quick_chat = { default_model = 'opencode/muse-spark-1.3-contributor-free' },
    }
  end,

  dependencies = {
    'nvim-lua/plenary.nvim',

    -- {
    --   'MeanderingProgrammer/render-markdown.nvim',
    --   ft = { 'markdown', 'Avante', 'copilot-chat', 'opencode_output' },
    --
    --   opts = {
    --     enabled = false,
    --     anti_conceal = { enabled = false },
    --     file_types = { 'markdown', 'opencode_output' },
    --     render = {
    --       latex = true, -- Enable LaTeX math rendering
    --     },
    --   },
    -- },

    {
      'OXY2DEV/markview.nvim',
      ft = { 'markdown', 'typst', 'opencode_output', 'yaml', 'toml' },

      keys = {
        {
          '<leader>tm',
          function()
            local msg = 'Markview '
            if not vim.g.markview then
              vim.cmd 'Markview attach'
              msg = msg .. 'enabled'
            else
              vim.cmd 'Markview detach'
              msg = msg .. 'disabled'
            end
            vim.notify(msg, vim.g.markview and vim.log.levels.WARN or vim.log.levels.INFO, { title = 'Markview' })
            vim.g.markview = not vim.g.markview
          end,
          desc = '[T]oggle [M]arkview',
        },
      },

      ---@module 'markview.nvim'
      ---@type markview.config
      opts = {
        markdown = {
          enable = true,
        },
        markdown_inline = {
          enable = true,
        },
      },

      config = function()
        vim.g.markview = false
        vim.cmd 'Markview Stop'
        --- Autocmd that disables line numbers in markdown files when markview is attaches
        --- Should also check if line numbers are enabled before markview is attached, and restore them when markview is detached
        vim.api.nvim_create_autocmd('User', {
          pattern = 'MarkviewAttach',
          callback = function()
            vim.wo.number = vim.wo.number and false
            vim.wo.relativenumber = vim.wo.relativenumber and false
          end,
        })
        vim.api.nvim_create_autocmd('User', {
          pattern = 'MarkviewDetach',
          callback = function()
            vim.wo.number = not vim.wo.number and true
            vim.wo.relativenumber = not vim.wo.relativenumber and true
          end,
        })
      end,
    },

    'saghen/blink.cmp',
    'folke/snacks.nvim',
  },
}

return {
  M.copilot,
  M.opencode,
}
