-- Example for configuring Neovim to load user-installed installed Lua rocks:
package.path = package.path .. ';' .. vim.fn.expand '$HOME' .. '/.luarocks/share/lua/5.1/?/init.lua'
package.path = package.path .. ';' .. vim.fn.expand '$HOME' .. '/.luarocks/share/lua/5.1/?.lua'

local image = {
  '3rd/image.nvim',
  event = 'VeryLazy',
  config = true,
}

local hologram = {
  'edluffy/hologram.nvim',
  config = function()
    require('hologram').setup {
      auto_display = true,
    }
  end,
}

local img_clip = {
  'HakonHarnes/img-clip.nvim',
  event = 'VeryLazy',
  opts = {},
  keys = {
    { '<leader>p', '<cmd>PasteImage<cr>', desc = 'Paste image from system clipboard' },
  },
}

image.opts = {
  backend = 'kitty',

  max_width = nil,
  max_height = nil,
  max_width_window_percentage = nil,
  max_height_window_percentage = 25,

  window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
  window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },

  editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
  tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)

  hijack_file_patterns = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp', '*.svg' }, -- render image files as images when opened
}

image.opts.integrations = {
  markdown = {
    enabled = false,
    clear_in_insert_mode = false,
    download_remote_images = false,
    only_render_image_at_cursor = false,
    filetypes = { 'markdown', 'vimwiki' }, -- markdown extensions (ie. quarto) can go here
  },

  neorg = {
    enabled = true,
    clear_in_insert_mode = false,
    download_remote_images = true,
    only_render_image_at_cursor = false,
    filetypes = { 'norg' },
  },

  html = { enabled = false },
  css = { enabled = false },
}

local M = {
  image,
}

return M
