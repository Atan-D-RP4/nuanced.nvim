local preset_one = function()
  local wilder = require 'wilder'
  --
  -- local gradient = {
  --   '#f4468f',
  --   '#fd4a85',
  --   '#ff507a',
  --   '#ff566f',
  --   '#ff5e63',
  --   '#ff6658',
  --   '#ff704e',
  --   '#ff7a45',
  --   '#ff843d',
  --   '#ff9036',
  --   '#f89b31',
  --   '#efa72f',
  --   '#e6b32e',
  --   '#dcbe30',
  --   '#d2c934',
  --   '#c8d43a',
  --   '#bfde43',
  --   '#b6e84e',
  --   '#aff05b',
  -- }
  --
  -- for i, fg in ipairs(gradient) do
  --   gradient[i] = wilder.make_hl('WilderGradient' .. i, 'Pmenu', { { a = 1 }, { a = 1 }, { foreground = fg } })
  -- end
  --
  wilder.setup {
    modes = { '/', '?', ':' },
    pipeline = {
      wilder.cmdline_pipeline {
        fuzzy = 2,
      },
    },
  }

  -- Disable Python remote plugin
  wilder.set_option('use_python_remote_plugin', 0)

  wilder.set_option(
    'renderer',
    wilder.popupmenu_renderer(wilder.popupmenu_border_theme {
      highlights = {
        border = 'Normal', -- highlight to use for the border
      },
      -- 'single', 'double', 'rounded' or 'solid'
      -- can also be a list of 8 characters, see :h wilder#popupmenu_border_theme() for more details
      border = 'rounded',
    })
  )

  wilder.set_option(
    'renderer',
    wilder.renderer_mux {
      [':'] = wilder.popupmenu_renderer(wilder.popupmenu_border_theme {
        highlighter = wilder.highlighter_with_gradient {
          wilder.basic_highlighter(),
        },
        highlights = {
          border = 'TelescopeBorder',
          accent = wilder.make_hl('WilderAccent', 'Pmenu', { { a = 1 }, { a = 1 }, { foreground = '#5FF1FF' } }),
          -- gradient = gradient,
        },
        border = 'Normal',
        pumblend = 0,
        max_height = 10,
      }),

      ['/'] = wilder.wildmenu_renderer {
        highlighter = wilder.basic_highlighter(),
      },
    }
  )
end

local preset_two = function()
  local wilder = require 'wilder'
  wilder.setup {
    modes = { '/', '?', ':' },
    pipeline = {
      wilder.cmdline_pipeline {
        fuzzy = 2,
      },
    },
  }
  wilder.set_option(
    'renderer',
    wilder.popupmenu_renderer {
      highlighter = wilder.basic_highlighter(),
      highlights = {
        border = 'TelescopeBorder',
        accent = wilder.make_hl('WilderAccent', 'Pmenu', { { a = 1 }, { a = 1 }, { foreground = '#5FF1FF' } }),
      },
      border = 'rounded',
      pumblend = 0,
    }
  )
end

return {
  'gelguy/wilder.nvim',
  enabled = false,
  events = { 'CmdlineEnter', 'UIEnter' },

  config = preset_one,
}
