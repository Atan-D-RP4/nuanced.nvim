-- [[ Setting options ]]

-- NOTE: You can change these options as you wish!

local opt = vim.opt

-- opt.isfname:append '@-@'

opt.cmdheight = 0

opt.shell = vim.fn.executable '/bin/fish' == 1 and '/bin/fish' or '/bin/bash'

opt.gcr = {
  'i-c-ci-ve:-block-TermCursor',
  'n-v:block-Cursor/lCursor',
  'o:hor50-Cursor/lCursor',
  'r-cr:hor20-Cursor/lCursor',
}

opt.termguicolors = true -- set term gui colors (most terminals support this)

-- disable nvim intro (Snacks takes care of it)
-- opt.shortmess:append 's'

-- set messagesopt
if vim.fn.exists 'messagesopt' == 1 then
  opt.messagesopt:append 'wait:500'
  opt.messagesopt:remove 'hit-enter'
end

if vim.fn.exists 'diffopt' == 1 then
  opt.diffopt = 'algorithm:histogram,anchor,internal,filler,closeoff,inline:char,linematch:40'
end

-- Separate vim plugins from neovim in case vim still in use
opt.runtimepath:remove '/usr/share/vim/vimfiles'

-- Make line numbers default
opt.number = true
opt.relativenumber = true
opt.ruler = false -- Because we have statusline

-- Enable mouse mode, can be useful for resizing splits for example!
opt.mouse = 'a'
opt.mousehide = true

-- Don't show the mode, since it's already in the status line
opt.showmode = false
opt.laststatus = 2

-- Command-line History
opt.history = 10000

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
opt.ignorecase = true
opt.smartcase = true

-- Tab Settings
opt.smarttab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = false

-- Enable auto-indenting
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
opt.updatetime = 300

-- Configure how new splits should be opened
opt.splitright = true
opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣', extends = '›', precedes = '‹' }
opt.fillchars = {
  vert = '│',
  eob = ' ',
  diff = '─',
  msgsep = '‾',
}

-- Enable break indent
opt.breakindent = true
-- opt.breakindentopt = 'shift:4,min:20'
-- opt.showbreak = '↪'

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
opt.whichwrap:append '<>[]hl'
opt.wrap = true
opt.textwidth = 80
opt.linebreak = true

opt.smoothscroll = true

-- Preview substitutions live, as you type!
opt.inccommand = 'split'

-- Undercurl
vim.cmd [[let &t_Cs = "\e[4:3m"]]
vim.cmd [[let &t_Ce = "\e[4:0m"]]

-- Show which line your cursor is on
opt.cursorline = true
opt.cursorlineopt = 'both'

-- Minimal number of screen lines to keep above and below the cursor.
opt.scrolloff = 999

opt.jumpoptions:append 'view'

opt.hidden = true
opt.encoding = 'utf-8'
opt.fileencoding = 'utf-8'
opt.path:append '**'
opt.autoread = true

-- Sync clipboard between OS and Neovim.
-- Schedule the setting after `UiEnter` because it can increase startup-time.
vim.schedule(function()
  -- Check if clipboard support is available
  if vim.fn.has 'clipboard' == 0 then
    return
  end

  -- Platform-specific clipboard configuration
  vim.opt.clipboard = 'unnamedplus,unnamed'
  vim.g.clipboard = {
    name = 'OSC 52 with improved fallbacks',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy '+',
      ['*'] = require('vim.ui.clipboard.osc52').copy '*',
    },
    cache_enabled = 1,
  }
end)

local cache_dir = vim.fn.stdpath 'cache'
vim.schedule(function()
  vim.tbl_map(function(dir)
    local name, path = unpack(dir)
    local created_or_exist = (function()
      -- Create directories if they don't exist
      local ok, err, err_name = vim.uv.fs_mkdir(path, 493) -- 0755 in octal
      if not ok and err_name ~= 'EEXIST' then
        return false
      end
      return true
    end)()

    if not created_or_exist then
      vim.notify('Failed to create ' .. name .. ': ' .. path, vim.log.levels.ERROR)
    end
    vim.opt[name] = path
  end, {
    { 'undodir', cache_dir .. '/undo' },
    { 'backupdir', cache_dir .. '/backup' },
    { 'directory', cache_dir .. '/swap' },
  })
end)

-- Save undo history
opt.undofile = true
opt.undolevels = 1000
opt.undoreload = 10000

-- Swap files
opt.swapfile = true

-- Backup Files
opt.backup = true

vim.g.treesitter_diagnostics = true
vim.g.treesitter_lint_available = vim.fn.has 'nvim-0.11' == 1
vim.g.treesitter_folding_enabled = true

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0

opt.foldmethod = 'expr'
opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
opt.foldtext = 'v:lua.require("nuance.core.utils").custom_foldtext()'
opt.foldlevel = vim.g.treesitter_folding_enabled and 99 or 0
opt.fillchars:append { fold = ' ', foldopen = '▾', foldclose = '▸', foldsep = '│' }

-- opt.winborder = 'rounded'

-- vim.g.netrw_banner = 0
-- vim.g.netrw_fastbrowse = 1
-- vim.g.netrw_keepdir = 1
-- vim.g.netrw_silent = 1
-- vim.g.netrw_special_syntax = 1
-- vim.g.netrw_bufsettings = 'noma nomod nonu nowrap ro nobl relativenumber'
-- vim.g.netrw_liststyle = 3
-- vim.g.netrw_browse_split = 4
-- vim.cmd [[
--     let g:netrw_list_hide = netrw_gitignore#Hide()
--     let g:netrw_list_hide.=',\(^\|\s\s\)\zs\.\S\+'
--   ]]

-- vim: ts=2 sts=2 sw=2 et
