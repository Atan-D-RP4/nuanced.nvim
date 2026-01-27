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
      if statusline.is_truncated(args.trunc_width) or vim.bo.buftype ~= '' then
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

    -- Get effective background color from a highlight group.
    -- Handles: reverse attribute (swaps fg/bg visually), linked groups.
    -- For reverse highlights: visual_bg = fg, visual_fg = bg
    -- Returns nil if no usable background can be determined.
    local function get_effective_bg(name)
      local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
      if not next(hl) then
        return nil
      end
      local bg = hl.reverse and hl.fg or hl.bg
      return bg
    end

    -- Get effective foreground color from a highlight group.
    local function get_effective_fg(name)
      local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
      if not next(hl) then
        return nil
      end
      local fg = hl.reverse and hl.bg or hl.fg
      return fg
    end

    -- Try multiple highlight groups, return first valid bg
    local function get_bg_with_fallbacks(...)
      for _, name in ipairs { ... } do
        local bg = get_effective_bg(name)
        if bg then
          return bg
        end
      end
      return nil
    end

    -- Create transition highlight for powerline separators (█).
    -- The █ char shows as fg color on bg color background.
    -- For clean transitions: fg = section's bg, bg = StatusLine's bg
    local function make_transition_hl(section_hl)
      local section_bg = get_bg_with_fallbacks(section_hl, 'StatusLine', 'Normal')
      local statusline_bg = get_effective_bg 'StatusLine'

      if not section_bg then
        return
      end

      vim.api.nvim_set_hl(0, section_hl .. '2', {
        fg = section_bg,
        bg = statusline_bg,
      })
    end

    -- Ensure MiniStatusline base highlights exist for colorschemes that don't define them
    local function ensure_mini_highlights()
      local statusline_bg = get_effective_bg 'StatusLine'
      local statusline_fg = get_effective_fg 'StatusLine'
      local normal_fg = get_effective_fg 'Normal'

      -- If MiniStatuslineFilename is empty, create it from StatusLine
      local filename_hl = vim.api.nvim_get_hl(0, { name = 'MiniStatuslineFilename', link = false })
      if not next(filename_hl) then
        vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', {
          fg = normal_fg or statusline_fg,
          bg = statusline_bg,
        })
      end

      -- Mode highlights: always use distinct colors for visual clarity
      -- These are vim's traditional mode colors adapted for modern themes
      local mode_colors = {
        MiniStatuslineModeNormal = { fg = 0x000000, bg = 0x87afaf }, -- cyan-ish
        MiniStatuslineModeInsert = { fg = 0x000000, bg = 0x87af5f }, -- green
        MiniStatuslineModeVisual = { fg = 0x000000, bg = 0xd7af5f }, -- orange/yellow
        MiniStatuslineModeReplace = { fg = 0x000000, bg = 0xd78787 }, -- red/pink
        MiniStatuslineModeCommand = { fg = 0x000000, bg = 0xd7af5f }, -- orange/yellow
        MiniStatuslineModeOther = { fg = 0x000000, bg = 0x8787af }, -- purple
      }

      for name, colors in pairs(mode_colors) do
        local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
        -- Check effective bg (accounting for reverse attribute)
        local effective_bg = hl.reverse and hl.fg or hl.bg
        -- Set if empty OR if existing highlight has no usable bg
        local has_valid_bg = next(hl) and effective_bg and effective_bg > 0
        if not has_valid_bg then
          vim.api.nvim_set_hl(0, name, { fg = colors.fg, bg = colors.bg, bold = true })
        end
      end

      -- Devinfo and Fileinfo
      for _, name in ipairs { 'MiniStatuslineDevinfo', 'MiniStatuslineFileinfo' } do
        local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
        if not next(hl) then
          vim.api.nvim_set_hl(0, name, { fg = normal_fg, bg = statusline_bg })
        end
      end
    end

    local function refresh_statusline_colors()
      ensure_mini_highlights()

      local mode_hls = {
        'MiniStatuslineModeNormal',
        'MiniStatuslineModeInsert',
        'MiniStatuslineModeVisual',
        'MiniStatuslineModeReplace',
        'MiniStatuslineModeCommand',
        'MiniStatuslineModeOther',
      }
      for _, mode_hl in ipairs(mode_hls) do
        make_transition_hl(mode_hl)
      end
      make_transition_hl 'MiniStatuslineDevinfo'
      make_transition_hl 'MiniStatuslineFileinfo'
      make_transition_hl 'MiniStatuslineFilename'
    end

    -- Defer to ensure mini.statusline has set up its highlights first
    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('statusline-colors', { clear = true }),
      pattern = '*',
      callback = function()
        -- Defer to run after mini.statusline has processed the colorscheme change
        vim.defer_fn(function()
          refresh_statusline_colors()
        end, 50)
      end,
    })

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
      refresh_statusline_colors()
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
  matugen_base16 = {
    'nvim-mini/mini.base16',
    version = false,
    config = function()
      require('matugen').setup()
      -- Register a signal handler for SIGUSR1 (matugen updates)
      local signal = vim.uv.new_signal()
      assert(signal, 'Failed to create new signal')
      signal:start(
        'sigusr1',
        vim.schedule_wrap(function()
          vim.notify('Reloading matugen theme due to SIGUSR1 signal', vim.log.levels.INFO, {
            title = 'matugen',
          })
          package.loaded['matugen'] = nil
          require('matugen').setup()

          -- Any other options you wish to set upon matugen reloads can also go here!
          -- Make comments italic
          vim.api.nvim_set_hl(0, 'Comment', { italic = true })
        end)
      )
    end,
  },

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
      enabled = false,
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
  themes.catpuccin,
  -- themes.matugen_base16,
  icons,
  noice,
}

return M
-- vim: ts=2 sts=2 sw=2 et
