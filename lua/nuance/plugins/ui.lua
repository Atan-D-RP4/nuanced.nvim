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

local tabline = {
  'echasnovski/mini.tabline',
  event = 'VimEnter',
  init = function()
    vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete' }, {
      group = vim.api.nvim_create_augroup('nuance-mini-buftabs', { clear = true }),
      pattern = '*',
      callback = function()
        local bufs = vim.api.nvim_list_bufs()
        -- Check if vim.g.buftabs exists
        local loaded = vim.g.bufs or {}
        for _, bufnr in ipairs(bufs) do
          if
            vim.api.nvim_get_option_value('buflisted', { buf = bufnr }) == true
            -- Check whether the buffer is a scratch buffer
            and vim.api.nvim_buf_get_name(bufnr):len() > 0
          then
            table.insert(loaded, bufnr)
          end
        end
        vim.g.buftabs = loaded
      end,
    })
    require('mini.tabline').setup {
      format = function(buf_id, label)
        local tabline = MiniTabline.default_format(buf_id, label)
        local bufs = vim.g.buftabs
        for i, item in ipairs(bufs) do
          if item == buf_id then
            tabline = tabline .. string.format('[%s] ', i)
            break
          end
        end
        return tabline
      end,
      tabpage_section = 'right',
    }
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

-- Snacks.nvim also has a notifications module
-- So using that instead
local notify = {
  'echasnovski/mini.notify',
  event = 'VimEnter',
}

local themes = {
  tokyonight = {
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    init = function()
      vim.cmd.colorscheme 'tokyonight-night'
      vim.cmd.hi 'Comment gui=italic'
    end,
  },

  shadotheme = {
    'Shadorain/shadotheme',
    priority = 1000,
    init = function()
      vim.cmd [[
        colorscheme shado-legacy
        hi Keyword gui=italic
        hi WinBar guibg=None
        hi WinBarNC guibg=None
        hi Comment gui=italic
      ]]
    end,
  },

  witch = {
    'sontungexpt/witch',
    priority = 1000,
    lazy = false,
    config = function(_, opts)
      require('witch').setup(opts)
    end,
  },

  kanagawa = {
    'rebelot/kanagawa.nvim',
    priority = 1000,
    opts = {
      compile = true, -- enable compiling the colorscheme
      undercurl = true, -- enable undercurls
      commentStyle = { italic = true },
      functionStyle = {},
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = false, -- do not set background color
      dimInactive = false, -- dim inactive window `:h hl-NormalNC`
      terminalColors = true, -- define vim.g.terminal_color_{0,17}
      colors = { -- add/modify theme and palette colors
        palette = {},
        theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
      },
      overrides = function(colors) -- add/modify highlights
        return {}
      end,
      theme = 'wave', -- Load "wave" theme when 'background' option is not set
      background = { -- map the value of 'background' option to a theme
        dark = 'dragon', -- try "dragon" !
        light = 'lotus',
      },
    },
    init = function()
      vim.cmd [[
        colorscheme kanagawa
        hi Comment gui=italic
      ]]
    end,
  },

  catpuccin = {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1001,
    init = function()
      vim.cmd [[
        colorscheme catppuccin-mocha
        hi Comment gui=italic
      ]]
    end,
  },
}

local noice = {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'echasnovski/mini.notify',
  },
  opts = {
    presets = {
      command_palette = false,
    },
  },
}

local transparent = {
  'xiyaowong/nvim-transparent',
  event = 'VimEnter',
  config = true,
}

local M = {
  themes.witch,
  statusline,
  tabline,
  icons,
  -- noice,
  -- transparent,
}

return M
-- vim: ts=2 sts=2 sw=2 et
