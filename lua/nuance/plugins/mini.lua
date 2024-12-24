return {
  -- {
  --   'echasnovski/mini.icons',
  --   config = function()
  --     require('mini.icons').setup()
  --   end
  -- },

  -- {
  --   'echasnovski/mini.files',
  --   keys = {
  --     -- Open file explorer
  --     {
  --       '<leader>o',
  --       function()
  --         if not require('mini.files').close() then
  --           require('mini.files').open()
  --         end
  --       end,
  --       desc = "Open Mini's File Explorer",
  --     },
  --   },
  --
  --   opts = {
  --     options = {
  --       use_as_default_explorer = false,
  --     },
  --     windows = {
  --       -- Whether to show preview of file/directory under cursor
  --       preview = true,
  --     },
  --   },
  -- },

  { 'echasnovski/mini.notify', event = 'VimEnter' },

  -- {
  --   'echasnovski/mini.ai',
  --   event = { 'VeryLazy', 'BufRead', 'BufNewFile' },
  --   -- Better Around/Inside textobjects
  --   --
  --   -- Examples:
  --   --  - va)  - [V]isually select [A]round [)]paren
  --   --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
  --   --  - ci'  - [C]hange [I]nside [']quote
  --   config = function()
  --     require('mini.ai').setup { n_lines = 500 }
  --   end,
  -- },
  --
  {
    'echasnovski/mini.surround',
    event = { 'BufRead', 'BufNewFile' },

    opts = {
      mappings = {
        add = '<leader>sa',
        delete = '<leader>sd',
        find = '<leader>sf',
        find_left = '<leader>sF',
        highlight = '<leader>sh',
        replace = '<leader>sr',
        suffix_last = 'l',
        suffix_next = 'n',
      },
    },
  },

  {
    'echasnovski/mini.tabline',
    event = 'VimEnter',
    init = function()
      require('mini.tabline').setup {}
    end,
  },

  {
    'echasnovski/mini.statusline',
    event = 'VimEnter',

    -- Simple and easy statusline.
    --  You could remove this setup call if you don't like it,
    --  and try some other statusline plugin
    config = function()
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

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_fileinfo = function(args)
        local size_fn = function()
          local size = vim.fn.getfsize(vim.fn.getreg '%')
          if size < 1024 then
            return string.format('%dB', size)
          elseif size < 1048576 then
            return string.format('%.2fKiB', size / 1024)
          else
            return string.format('%.2fMiB', size / 1048576)
          end
        end

        local filetype = vim.bo.filetype

        -- Don't show anything if there is no filetype
        if filetype == '' then
          return ''
        end
        -- Construct output string if truncated or buffer is not normal
        if MiniStatusline.is_truncated(args.trunc_width) or vim.bo.buftype ~= '' then
          return filetype
        end

        -- Construct output string with extra file info
        local encoding = vim.bo.fileencoding or vim.bo.encoding
        local format = vim.bo.fileformat
        local word = vim.fn.wordcount()
        local words = string.format('%d-%d', word.words, word.chars)

        return string.format('%s %s[%s] %s %s', filetype, encoding, format, size_fn(), words)
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
