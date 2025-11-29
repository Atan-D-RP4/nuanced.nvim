---@diagnostic disable: unused-local
local statusline = {
  'echasnovski/mini.statusline',
  event = 'UIEnter',
  -- Simple and easy statusline.
  -- You could remove this setup call if you don't like it,
  -- and try some other statusline plugin
  config = function()
    local statusline = require 'mini.statusline'
    -- set use_icons to true if you have a Nerd Font
    -- You can configure sections in the statusline by overriding their
    -- default behavior.
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_fileinfo = function(args)
      local size_fn = function()
        local size = vim.fn.getfsize(vim.fn.getreg '%')
        if size < 1024 then
          return string.format('%dB', size)
        elseif size < 1048576 then
          return string.format('%.2fKiB', size / 1024)
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
      local words = string.format('%dW', word.words)

      return string.format('%s %s[%s] %s %s', filetype, encoding, format, size_fn(), words)
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l|%-2v'
    end

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
      local fghl = vim.api.nvim_get_hl(0, { name = hl_fg })
      local bghl = vim.api.nvim_get_hl(0, { name = hl_bg })
      fghl.fg = fghl.bg
      fghl.bg = bghl.bg
      ---@diagnostic disable-next-line: inject-field
      fghl.force = true
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.api.nvim_set_hl(0, hl_fg .. '2', fghl)
    end

    require('nuance.core.promise').async_promise(100, function()
      statusline.setup {

        content = {
          -- Content for active window
          active = function()
            local mode, mode_hl = statusline.section_mode { trunc_width = 50 }
            local git = statusline.section_git { trunc_width = 40 }
            -- local diff = statusline.section_diff { trunc_width = 75 }
            local diagnostics = statusline.section_diagnostics { trunc_width = 75 }
            local lsp = statusline.section_lsp { trunc_width = 75 }
            local filename = statusline.section_filename { trunc_width = 140 }
            local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
            local location = statusline.section_location { trunc_width = 75 }
            local search = statusline.section_searchcount { trunc_width = 75 }

            make_color(mode_hl, 'MiniStatuslineFilename')
            make_color('MiniStatuslineDevinfo', 'MiniStatuslineFilename')
            make_color('MiniStatuslineFileInfo', 'MiniStatuslineFilename')

            local tab = {
              { hl = mode_hl .. '2', strings = { '█' } },
              { hl = mode_hl, strings = { mode } },
              { hl = mode_hl .. '2', strings = { '█' } },
              '%<', -- Mark general truncate point
            }
            -- if table.concat({ git, diff }):len() > 0 then
            if table.concat({ git }):len() > 0 then
              table.insert(tab, { hl = 'MiniStatuslineDevinfo2', strings = { '█' } })
              table.insert(tab, { hl = 'MiniStatuslineDevinfo', strings = { git } })
              table.insert(tab, { hl = 'MiniStatuslineDevinfo2', strings = { '█' } })
              table.insert(tab, '%<') -- Mark general truncate point
            end
            table.insert(tab, { hl = 'MiniStatuslineFilename', strings = { ' ', filename, ' ' } })
            table.insert(tab, '%=')
            if table.concat({ diagnostics, lsp }):len() > 0 then
              table.insert(tab, { hl = 'MiniStatuslineDevinfo2', strings = { '█' } })
              table.insert(tab, { hl = 'MiniStatuslineDevinfo', strings = { diagnostics, lsp } })
              table.insert(tab, { hl = 'MiniStatuslineDevinfo2', strings = { '█' } })
            end
            if fileinfo:len() > 0 then
              table.insert(tab, { hl = 'MiniStatuslineFileinfo2', strings = { '█' } })
              table.insert(tab, { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } })
              table.insert(tab, { hl = 'MiniStatuslineFileinfo2', strings = { '█' } })
            end

            table.insert(tab, { hl = mode_hl .. '2', strings = { '█' } })
            table.insert(tab, { hl = mode_hl, strings = { search, location } })
            table.insert(tab, { hl = mode_hl .. '2', strings = { '█' } })
            -- Usage of `MiniStatusline.combine_groups()` ensures highlighting and
            -- correct padding with spaces between groups (accounts for 'missing'
            -- sections, etc.)
            return combine_groups(tab)
          end,
          -- Content for inactive window(s)
          inactive = nil,
        },
        use_icons = vim.g.have_nerd_font,
        set_vim_settings = true,
      }
    end)
  end,
}

local icons = {
  'echasnovski/mini.icons',
  event = 'UIEnter',
  config = function()
    require('mini.icons').setup()
  end,
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
      overrides = function(_colors) -- add/modify highlights
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
        colorscheme kanagawa-wave
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
  event = 'UIEnter',
  dependencies = { 'MunifTanjim/nui.nvim' },
  -- config = function(_, opts)
  --   require('nuance.core.promise').async_promise(100, function()
  --     require('noice').setup(opts)
  --     if Snacks ~= nil then
  --       Snacks.picker.notifications = function()
  --         require('noice').cmd 'snacks'
  --       end
  --     end
  --   end)
  -- end,

  ---@module 'noice'
  ---@type NoiceConfig
  opts = {
    lsp = {
      override = {
        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
        ['vim.lsp.util.stylize_markdown'] = true,
        ['cmp.entry.get_documentation'] = true,
      },

      signature = {
        enabled = false,
        view = nil, -- when nil, use defaults from documentation
        ---@type NoiceViewOptions
        opts = {}, -- merged with defaults from documentation
      },
    },

    ---@type NoiceRouteConfig[]
    routes = {
      {
        filter = {
          event = 'msg_show',
          any = {
            { find = '%d+L, %d+B' },
            { find = '; after #%d+' },
            { find = '; before #%d+' },
          },
        },
        view = 'mini',
      },
    },

    cmdline = {
      ---@type table<string, CmdlineFormat>
      format = {
        selections = { pattern = ":'<,'>", title = ' Selections ' },
        filter = { pattern = { '^:%s*!', '^:.!' }, icon = '$', lang = 'bash' },
      },
    },

    presets = {
      lsp_doc_border = vim.o.winborder == '' and false or true, -- add a border to hover docs and signature help
      command_palette = true,
      long_message_to_split = true, -- long messages will be sent to a split
    },

    redirect = { filter = '' },
  },
}

local which_key = { -- Useful plugin to show you pending keybinds.
  'folke/which-key.nvim',
  event = 'UIEnter', -- Sets the loading event to 'UIEnter'
  opts = {
    expand = function(node)
      return not node.desc
    end,

    icons = {
      -- set icon mappings to true if you have a Nerd Font
      mappings = vim.g.have_nerd_font,
      -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
      -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
      keys = vim.g.have_nerd_font and {} or {
        Up = '<Up> ',
        Down = '<Down> ',
        Left = '<Left> ',
        Right = '<Right> ',
        C = '<C-ΓÇª> ',
        M = '<M-ΓÇª> ',
        D = '<D-ΓÇª> ',
        S = '<S-ΓÇª> ',
        CR = '<CR> ',
        Esc = '<Esc> ',
        ScrollWheelDown = '<ScrollWheelDown> ',
        ScrollWheelUp = '<ScrollWheelUp> ',
        NL = '<NL> ',
        BS = '<BS> ',
        Space = '<Space> ',
        Tab = '<Tab> ',
        F1 = '<F1>',
        F2 = '<F2>',
        F3 = '<F3>',
        F4 = '<F4>',
        F5 = '<F5>',
        F6 = '<F6>',
        F7 = '<F7>',
        F8 = '<F8>',
        F9 = '<F9>',
        F10 = '<F10>',
        F11 = '<F11>',
        F12 = '<F12>',
      },
    },

    win = { wo = { winblend = 20 } },

    -- Document existing key chains
    spec = {
      { '<leader>f', group = '[F]uzzy Find' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>s', group = '[S]urround', mode = 'n' },
      { '<leader>g', group = '[G]it', mode = 'n' },
      { '<leader>x', group = '[x] Trouble' },
      { '<leader>a', group = '[a] Session/Avante', mode = 'n' },
      { '<leader>e', group = '[e] Buffer-Switching', mode = 'n' },
    },
  },

  config = function(_, opts)
    require('nuance.core.promise').async_promise(100, function()
      require('which-key').setup(opts)
    end)
  end,
}

local M = {
  which_key,
  statusline,
  themes.tokyonight,
  icons,
  noice,
}

return M
-- vim: ts=2 sts=2 sw=2 et
