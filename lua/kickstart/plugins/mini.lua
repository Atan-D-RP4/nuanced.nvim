return {
  -- {
  --   'echasnovski/mini.icons',
  --   config = function()
  --     require('mini.icons').setup()
  --   end
  -- },

  {
    'echasnovski/mini.notify',
    event = 'VeryLazy',
    config = function()
      require('mini.notify').setup()
    end,
  },

  {
    'echasnovski/mini.ai',
    event = 'VeryLazy',
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    config = function()
      require('mini.ai').setup { n_lines = 500 }
    end,
  },

  {
    'echasnovski/mini.surround',
    event = 'VeryLazy',

    config = function()
      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      local surroud_prefix = '<leader>s'
      require('mini.surround').setup {
        mappings = {
          add = surroud_prefix .. 'a', -- Add surrounding in Normal and Visual modes
          delete = surroud_prefix .. 'd', -- Delete surrounding
          find = surroud_prefix .. 'f', -- Find surrounding (to the right)
          find_left = surroud_prefix .. 'F', -- Find surrounding (to the left)
          highlight = surroud_prefix .. 'h', -- Highlight surrounding
          replace = surroud_prefix .. 'r', -- Replace surrounding
          update_n_lines = surroud_prefix .. 'n', -- Update `n_lines`

          suffix_last = 'l', -- Suffix to search with "prev" method
          suffix_next = 'n', -- Suffix to search with "next" method
        },
      }
    end,
  },

  {
    'echasnovski/mini.tabline',
    event = 'VimEnter',
    config = function()
      require('mini.tabline').setup()
    end,
  },

  {
    'echasnovski/mini.statusline',
    event = 'VimEnter',

    config = function()
      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'

      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      -- Create a custom section in the statusline for session
      statusline.section_session = function()
        local session = require 'mini.sessions'
        local session_name = session.get_current_session_name()
        return session_name and 'Session: ' .. session_name or ''
      end
    end,
  },

  -- { -- Collection of various small independent plugins/modules
  --   'echasnovski/mini.nvim',
  --   event = 'VeryLazy',
  --   config = function()
  --     require('mini.icons').setup()
  --
  --     require('mini.ai').setup { n_lines = 500 }
  --
  --     require('mini.surround').setup {
  --       mappings = {
  --         add = 'gsa',
  --         delete = 'gsd',
  --       },
  --     }
  --
  --     -- ... and there is more!
  --     --  Check out: https://github.com/echasnovski/mini.nvim
  --   end,
  -- },
}

-- vim: ts=2 sts=2 sw=2 et
