local M = {}

function M.setup()
  require('mini.base16').setup {
    use_cterm = true,

    plugins = {
      default = false,
      ['nvim-mini/mini.nvim'] = true,
    },

    palette = {
      -- Background tones
      base00 = '{{ dank16.color0.default.hex }}', -- Default Background
      base01 = '{{ dank16.color1.default.hex }}', -- Lighter Background (status bars)
      base02 = '{{ dank16.color2.default.hex }}', -- Selection Background
      base03 = '{{ dank16.color3.default.hex }}', -- Comments, Invisibles

      -- Foreground tones
      base04 = '{{ dank16.color4.default.hex }}', -- Dark Foreground (status bars)
      base05 = '{{ dank16.color5.default.hex }}', -- Default Foreground
      base06 = '{{ dank16.color6.default.hex }}', -- Light Foreground
      base07 = '{{ dank16.color7.default.hex }}', -- Lightest Foreground

      -- Accent colors
      base08 = '{{ dank16.color8.default.hex }}', -- Variables, XML Tags, Errors
      base09 = '{{ dank16.color9.default.hex }}', -- Integers, Constants
      base0A = '{{ dank16.color10.default.hex }}', -- Classes, Search Background
      base0B = '{{ dank16.color11.default.hex }}', -- Strings, Diff Inserted
      base0C = '{{ dank16.color12.default.hex }}', -- Regex, Escape Chars
      base0D = '{{ dank16.color13.default.hex }}', -- Functions, Methods
      base0E = '{{ dank16.color14.default.hex }}', -- Keywords, Storage
      base0F = '{{ dank16.color15.default.hex }}', -- Deprecated, Embedded Tags
    },
  }

  -- Make selected text stand out more
  vim.api.nvim_set_hl(0, 'Visual', {
    bg = '{{colors.on_surface_variant.default.hex}}',
    fg = '{{colors.background.default.hex}}',
  })
end

return M
