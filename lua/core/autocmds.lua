-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    local clip = '/mnt/c/Windows/System32/clip.exe'
    if vim.fn.executable(clip) == 1 then
      if vim.v.event.operator == 'y' then
        vim.fn.system(clip, vim.fn.getreg '0')
      end
    end
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('VimResized', {
  desc = 'Resize splits when resizing the window',
  group = vim.api.nvim_create_augroup('kickstart-resize-splits', { clear = true }),
  callback = function()
    vim.cmd 'wincmd ='
  end,
})

-- Clear trailing whitespace on save
vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Clear trailing whitespace on save',
  group = vim.api.nvim_create_augroup('kickstart-clear-trailing-whitespace', { clear = true }),
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd [[keeppatterns %s/\s\+$//e]]
    vim.fn.winrestview(save)
  end,
})

-- Close buffer if the terminal is closed
vim.api.nvim_create_autocmd('TermClose', {
  pattern = '*',
  callback = function()
    vim.schedule(function()
      if (vim.bo.buftype == 'terminal' or vim.bo.filetype == 'lua') and vim.v.shell_error == 0 then
        vim.cmd('bdelete! ' .. vim.fn.expand '<abuf>')
      end
    end)
  end,
})

vim.api.nvim_create_autocmd('TermOpen', {
  pattern = '*',
  callback = function()
    vim.cmd [[
      setlocal nonumber norelativenumber
      setlocal nospell
    ]]
  end,
})

-- don't auto comment new line
vim.api.nvim_create_autocmd('BufEnter', { command = [[set formatoptions-=cro]] })

-- NOTE: (This works but needs to be improved for Cmdwin)
-- Toggle relative number on the basis of mode
-- local number_toggle_group = vim.api.nvim_create_augroup('NumberToggle', { clear = true })
-- vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'InsertLeave' }, {
--   pattern = '*',
--   callback = function()
--     vim.wo.relativenumber = true
--     vim.wo.number = true
--   end,
--   group = number_toggle_group,
-- })
-- vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost', 'InsertEnter' }, {
--   pattern = '*',
--   callback = function()
--     vim.wo.relativenumber = false
--     vim.wo.number = false
--   end,
--   group = number_toggle_group,
-- })

-- NOTE: Originally tried to put this in FileType event autocmd but it is apparently
-- too early for `set modifiable` to take effect
-- vim.api.nvim_create_autocmd('BufWinEnter', {
--   group = vim.api.nvim_create_augroup('YOUR_GROUP_HERE', { clear = true }),
--   desc = 'allow updating quickfix window',
--   pattern = 'quickfix',
--   callback = function(ctx)
--     vim.bo.modifiable = true
--     -- :vimgrep's quickfix window display format now includes start and end column (in vim and nvim) so adding 2nd format to match that
--     vim.bo.errorformat = '%f|%l col %c| %m,%f|%l col %c-%k| %m'
--     vim.keymap.set(
--     'n',
--     '<C-s>',
--     '<Cmd>cgetbuffer|set nomodified|echo "quickfix/location list updated"<CR>',
--     { buffer = true, desc = 'Update quickfix/location list with changes made in quickfix window' }
--     )
--   end,
-- })

-- vim: ts=2 sts=2 sw=2 et
