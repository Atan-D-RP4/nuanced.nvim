---@diagnostic disable: unused-local
local very_modded_statusline = {
  'echasnovski/mini.statusline',
  -- Simple and easy statusline.
  -- You could remove this setup call if you don't like it,
  -- and try some other statusline plugin
  config = function()
    local statusline = require 'mini.statusline'
    -- set use_icons to true if you have a Nerd Font

    local combine_groups = function(groups)
      local parts = vim.tbl_map(function(s)
        if type(s) == 'string' then
          return s
        end
        if type(s) ~= 'table' then
          return ''
        end

        local string_arr = vim.tbl_filter(function(x)
          return type(x) == 'string' and x ~= ''
        end, s.strings or {})
        local str = table.concat(string_arr, ' ')

        -- Use previous highlight group
        if s.hl == nil then
          return ' ' .. str .. ' '
        end

        -- Allow using this highlight group later
        if str:len() == 0 then
          return '%#' .. s.hl .. '#'
        end

        return string.format('%%#%s#%s', s.hl, str)
      end, groups)

      return table.concat(parts, '')
    end

    -- This function takes a hl class and updates the class with the BG
    -- of another class. The result is stored in a new group
    --@param hl_fg string : The highlight name of the highlight class
    --@param hl_bg string : The highlight name of a highlight class
    local make_color = function(hl_fg, hl_bg)
      ---@class vim.api.keyset.highlight
      local fghl = vim.api.nvim_get_hl(0, { name = hl_fg })
      local bghl = vim.api.nvim_get_hl(0, { name = hl_bg })
      fghl.fg = fghl.bg
      fghl.bg = bghl.bg
      fghl.force = true
      vim.api.nvim_set_hl(0, hl_fg .. '2', fghl)
    end

    statusline.setup {

      content = {
        -- Content for active window
        active = function()
          local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 50 }
          local git = MiniStatusline.section_git { trunc_width = 40 }
          local diff = MiniStatusline.section_diff { trunc_width = 75 }
          local diagnostics = MiniStatusline.section_diagnostics { trunc_width = 75 }
          local lsp = MiniStatusline.section_lsp { trunc_width = 75 }
          local filename = MiniStatusline.section_filename { trunc_width = 140 }
          local fileinfo = MiniStatusline.section_fileinfo { trunc_width = 120 }
          local location = MiniStatusline.section_location { trunc_width = 75 }
          local search = MiniStatusline.section_searchcount { trunc_width = 75 }

          -- Usage of `MiniStatusline.combine_groups()` ensures highlighting and
          -- correct padding with spaces between groups (accounts for 'missing'
          -- sections, etc.)
          --

          make_color(mode_hl, 'MiniStatuslineFilename')
          make_color('MiniStatuslineDevinfo', 'MiniStatuslineFilename')
          make_color('MiniStatuslineFileInfo', 'MiniStatuslineFilename')

          local tab = {
            { hl = mode_hl, strings = { mode } },
            { hl = mode_hl .. '2', strings = { '█' } },
            '%<', -- Mark general truncate point
          }
          if table.concat({ git, diff, diagnostics, lsp }):len() > 0 then
            table.insert(tab, { hl = 'MiniStatuslineDevinfo2', strings = { '█' } })
            table.insert(tab, { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics, lsp } })
            table.insert(tab, { hl = 'MiniStatuslineDevinfo2', strings = { '█' } })
            table.insert(tab, '%<') -- Mark general truncate point
          end
          table.insert(tab, { hl = 'MiniStatuslineFilename', strings = { ' ', filename, ' ' } })
          table.insert(tab, '%=')
          if fileinfo:len() > 0 then
            table.insert(tab, { hl = 'MiniStatuslineFileinfo2', strings = { '█' } })
            table.insert(tab, { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } })
            table.insert(tab, { hl = 'MiniStatuslineFileinfo2', strings = { '█' } })
          end

          table.insert(tab, { hl = mode_hl .. '2', strings = { '█' } })
          table.insert(tab, { hl = mode_hl, strings = { search, location } })
          return combine_groups(tab)
          -- return combine_groups {
          --   { hl = mode_hl, strings = { mode } },
          --   { hl = mode_hl .. '2', strings = { '█' } },
          --   '%<', -- Mark general truncate point
          --   { hl = 'MiniStatuslineDevinfo2', strings = { '█' } },
          --   { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics, lsp } },
          --   { hl = 'MiniStatuslineDevinfo2', strings = { '█' } },
          --   '%<', -- Mark general truncate point
          --   { hl = 'MiniStatuslineFilename', strings = { ' ', filename, ' ' } },
          --   '%=', -- End left alignment
          --   { hl = 'MiniStatuslineFileinfo2', strings = { '█' } },
          --   { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
          --   { hl = 'MiniStatuslineFileinfo2', strings = { '█' } },
          --   { hl = mode_hl .. '2', strings = { '█' } },
          --   { hl = mode_hl, strings = { search, location } },
          -- }
        end,
        -- Content for inactive window(s)
        inactive = nil,
      },
      use_icons = vim.g.have_nerd_font,
      set_vim_settings = true,
    }

    -- You can configure sections in the statusline by overriding their
    -- default behavior. For example, here we set the section for
    -- cursor location to LINE:COLUMN
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end
  end,
}

local icons = {
  'echasnovski/mini.icons',
  config = function()
    require('mini.icons').setup()
  end,
}

local files = {
  'echasnovski/mini.files',
  keys = {
    -- Open file explorer
    {
      '<leader>o',
      function()
        if not require('mini.files').close() then
          require('mini.files').open()
        end
      end,
      desc = "Open Mini's File Explorer",
    },
  },

  opts = {
    options = {
      use_as_default_explorer = false,
    },
    windows = {
      -- Whether to show preview of file/directory under cursor
      preview = true,
    },
  },
}

local notify = {
  'echasnovski/mini.notify',
  event = 'VimEnter',
}

local ai = {
  'echasnovski/mini.ai',
  event = { 'VeryLazy', 'BufRead', 'BufNewFile' },
  -- Better Around/Inside textobjects
  --
  -- Examples:
  --  - va)  - [V]isually select [A]round [)]paren
  --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
  --  - ci'  - [C]hange [I]nside [']quote
  config = function()
    require('mini.ai').setup { n_lines = 500 }
  end,
}

local surround = {
  'echasnovski/mini.surround',
  event = 'VimEnter',

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
}

local tabline = {
  'echasnovski/mini.tabline',
  event = 'VimEnter',
  init = function()
    require('mini.tabline').setup {}
  end,
}

local statusline = {
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
}

local M = {
  -- very_modded_statusline,
  icons,
  -- files,
  -- ai,
  notify,
  surround,
  tabline,
  statusline,
}

return M

-- vim: ts=2 sts=2 sw=2 et
