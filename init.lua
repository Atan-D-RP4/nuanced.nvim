-- Set to true if you have a Nerd Font installed and selected in the terminal
-- vim.g.have_nerd_font = true

-- vim.loader.enable()

-- [[ Load the core configuration ]]
require 'nuance.core'

-- [[ Install `lazy.nvim` plugin manager ]]
require 'lazy-bootstrap'

-- [[ Configure and install plugins ]]
require 'lazy-plugins'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
