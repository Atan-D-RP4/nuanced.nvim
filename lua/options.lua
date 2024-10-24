-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.ruler = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
-- vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'
vim.opt.mousehide = true

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Show Tabline
vim.opt.showtabline = 2

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  if vim.fn.has 'clipboard' == 0 then
    return
  end

  if vim.loop.os_uname().sysname == 'Windows_NT' then
    vim.opt.clipboard = 'unnamedplus'
    vim.g.clipboard = {
      name = 'clip.exe (WSL)',
      copy = {
        ['+'] = 'clip.exe',
        ['*'] = 'clip.exe',
      },
      paste = {
        ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
        ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      },
      cache_enabled = 0,
    }
    return
  end
  vim.opt.clipboard = 'unnamedplus,unnamed'
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000
vim.opt.undodir = '/tmp/.vim/undo.nvim'

-- Command-line History
vim.opt.history = 10000

-- Backup and Swap Files
vim.opt.swapfile = true
vim.opt.directory = '/tmp/.vim/swap.nvim'
vim.opt.backup = true
vim.opt.backupdir = '/tmp/.vim/backup.nvim'

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Tab and Indent Settings
vim.opt.smarttab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = false
vim.opt.smartindent = true
vim.opt.autoindent = true

-- Wild Menu and Pop-up Menue Settings
vim.opt.wildignore = '*.o,*.so*.obj,*~,*swp,*.exe'
vim.opt.wildmenu = true
vim.opt.wildmode = 'longest:full,full'
vim.opt.wildoptions = 'pum,fuzzy'
vim.opt.pumheight = 20
vim.opt.display = 'truncate'

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 10
vim.opt.timeoutlen = 1000

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

vim.opt.hidden = true
vim.opt.encoding = 'utf-8'
vim.opt.path:append '**'
vim.opt.autoread = true

-- Create directories if they don't exist
vim.fn.mkdir(vim.fn.expand '~/.vim/undo.nvim', 'p')
vim.fn.mkdir(vim.fn.expand '~/.vim/backup.nvim', 'p')
vim.fn.mkdir(vim.fn.expand '~/.vim/swap.nvim', 'p')

local clip = '/mnt/c/Windows/System32/clip.exe'
if vim.fn.executable(clip) == 1 then
  vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('WSLYank', { clear = true }),
    callback = function()
      if vim.v.event.operator == 'y' then
        vim.fn.system(clip, vim.fn.getreg '0')
      end
    end,
  })
end

-- vim: ts=2 sts=2 sw=2 et
