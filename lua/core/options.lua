-- [[ Setting options ]]
-- See `:help opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

local opt = vim.opt

opt.cmdheight = 1

if vim.fn.executable('/bin/fish') == 1 then
  opt.shell = '/bin/fish'
else
  opt.shell = '/bin/bash'
end

opt.gcr = {
  'i-c-ci-ve:-block-TermCursor',
  'n-v:block-Curosr/lCursor',
  'o:hor50-Curosr/lCursor',
  'r-cr:hor20-Curosr/lCursor',
}

opt.termguicolors = true -- set term gui colors (most terminals support this)

-- disable nvim intro
opt.shortmess:append 'sI'

-- separate vim plugins from neovim in case vim still in use
opt.runtimepath:remove '/usr/share/vim/vimfiles'

opt.foldenable = false

-- Make line numbers default
opt.number = true
opt.relativenumber = true
opt.ruler = false

-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
-- opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
opt.mouse = 'a'
opt.mousehide = true

-- Don't show the mode, since it's already in the status line
opt.showmode = false
vim.o.laststatus = 0

-- Show Tabline
opt.showtabline = 2

-- Enable break indent
opt.breakindent = true
opt.breakindentopt = 'shift:4,min:20'
opt.showbreak = '↪'

-- Save undo history
opt.undofile = true
opt.undolevels = 1000
opt.undoreload = 10000
opt.undodir = '/tmp/.vim/undo.nvim'

-- Command-line History
opt.history = 10000

-- Backup and Swap Files
opt.swapfile = true
opt.directory = '/tmp/.vim/swap.nvim'
opt.backup = true
opt.backupdir = '/tmp/.vim/backup.nvim'

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
opt.ignorecase = true
opt.smartcase = true

-- Tab and Indent Settings
opt.smarttab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = false
opt.smartindent = true
opt.autoindent = true

-- Wild Menu and Pop-up Menue Settings
opt.wildignore = '*.o,*.so*.obj,*~,*swp,*.exe'
opt.wildmenu = true
opt.wildmode = 'longest:full,full'
opt.wildoptions = 'pum,fuzzy,tagfile'
opt.pumheight = 10
opt.display = 'truncate'

-- Keep signcolumn on by default
opt.signcolumn = 'number'

-- Decrease update time
opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
opt.ttimeout = true
opt.ttimeoutlen = 10
opt.timeoutlen = 500

-- Configure how new splits should be opened
opt.splitright = true
opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
opt.fillchars = { vert = '│', eob = ' ' }

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
opt.whichwrap:append '<>[]hl'

-- Preview substitutions live, as you type!
opt.inccommand = 'split'

-- Show which line your cursor is on
opt.cursorline = true
opt.cursorlineopt = 'number'

-- Minimal number of screen lines to keep above and below the cursor.
opt.scrolloff = 10

opt.hidden = true
opt.encoding = 'utf-8'
opt.path:append '**'
opt.autoread = true

-- Create directories if they don't exist
vim.fn.mkdir(vim.fn.expand '~/.vim/undo.nvim', 'p')
vim.fn.mkdir(vim.fn.expand '~/.vim/backup.nvim', 'p')
vim.fn.mkdir(vim.fn.expand '~/.vim/swap.nvim', 'p')

-- add binaries installed by mason.nvim to path
local is_windows = vim.fn.has 'win32' ~= 0
local sep = is_windows and '\\' or '/'
local delim = is_windows and ';' or ':'
vim.env.PATH = table.concat({ vim.fn.stdpath 'data', 'mason', 'bin' }, sep) .. delim .. vim.env.PATH

-- vim: ts=2 sts=2 sw=2 et
