-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Neovide settings
if vim.g.neovide then
  local cursor_vfx = { 'railgun', 'torpedo', 'pixiedust', 'sonicboom', 'ripple', 'wireframe' }
  math.randomseed(os.time())

  vim.g.neovide_cursor_vfx_mode = cursor_vfx[math.random(1, #cursor_vfx)]

  vim.keymap.set('n', '<F11>', function()
    vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
  end, {})

  vim.g.neovide_scale_factor = 0.78
  vim.g.neovide_floating_blur_amount_x = 10.0
  vim.g.neovide_floating_blur_amount_y = 10.0
  vim.g.neovide_transparency = 0.9
  vim.g.neovide_hide_mouse_when_typing = true
  vim.g.neovide_refresh_rate = 24 -- 144, 60 This is fun to play with
  vim.g.neovide_refresh_rate_idle = 1
  vim.g.neovide_confirm_quit = false
  vim.g.neovide_no_idle = false
  vim.g.neovide_floating_corner_radius = 0.5

  vim.g.neovide_title_background_color = string.format('%x', vim.api.nvim_get_hl(0, { id = vim.api.nvim_get_hl_id_by_name 'Normal' }).bg)

  vim.g.neovide_title_text_color = 'pink'

  vim.o.laststatus = 0
  vim.o.cmdheight = 0
  vim.o.guifont = 'FantasqueSansM Nerd Font,:h20' -- Nerd fonts work well

  vim.cmd [[
    terminal
    startinsert
    autocmd BufLeave term://* quit
  ]]
else
  vim.loader.enable()

  -- [[ Load the core configuration ]]
  require 'nuance.core'

  -- [[ Install `lazy.nvim` plugin manager ]]
  -- [[ Configure and install plugins ]]
  require 'nuance.lazy'
end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
