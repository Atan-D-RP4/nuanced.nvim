-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('nuance-highlight-yank', { clear = true }),
  callback = function()
    local clip = '/mnt/c/Windows/System32/clip.exe'
    if vim.fn.executable(clip) == 1 then
      if vim.v.event.operator == 'y' then
        vim.fn.system(clip, vim.fn.getreg '0')
      end
    end
    if vim.hl ~= {} then
      vim.hl.on_yank()
    end
  end,
})

-- -- Trigger an Autocommand everytime the buffer list changes
-- vim.api.nvim_create_autocmd({'BufAdd', 'BufDelete'}, {
--   desc = 'Trigger an Autocommand everytime the buffer list changes',
--   group = vim.api.nvim_create_augroup('nuance-buffer-list-changes', { clear = true }),
--   callback = function()
--     if vim.g.listed_bufs == nil then
--       vim.g.listed_bufs = {}
--     else
--     end
--     local buffers = vim.api.nvim_list_bufs()
--     local tab_idx = 1
--     for _, buf in ipairs(buffers) do
--       if vim.api.nvim_buf_is_loaded(buf) then
--         vim.g.listed_bufs[tab_idx] = buf
--         tab_idx = tab_idx + 1
--       end
--     end
--   end,
-- })

vim.api.nvim_create_autocmd({ 'RecordingEnter', 'RecordingLeave' }, {
  callback = function(ev)
    -- NOTE: The oneliner that follows is equivalent to the if-else block below
    -- though it is less readable and can't use the `vim.notify` function
    -- vim.opt.cmdheight = ev.event == "RecordingEnter" and 1 or 0
    if ev.event == 'RecordingEnter' then
      vim.notify('Recording macro', vim.log.levels.INFO, { timeout = 500 })
      vim.opt.cmdheight = 1
    else
      vim.notify('Macro recorded', vim.log.levels.INFO, { timeout = 500 })
      vim.opt.cmdheight = 0
    end
  end,
})

vim.api.nvim_create_autocmd('VimResized', {
  desc = 'Resize splits when resizing the window',
  group = vim.api.nvim_create_augroup('nuance-resize-splits', { clear = true }),
  callback = function()
    vim.cmd 'wincmd ='
  end,
})

-- Clear trailing whitespace on save
vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Clear trailing whitespace on save',
  group = vim.api.nvim_create_augroup('nuance-clear-trailing-whitespace', { clear = true }),
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
    vim.opt.relativenumber = false
    vim.opt.spell = false
    vim.opt.number = false
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
vim.api.nvim_create_autocmd('BufWinEnter', {
  group = vim.api.nvim_create_augroup('EditQuickfix', { clear = true }),
  desc = 'allow updating quickfix window',
  pattern = 'quickfix',
  callback = function(ctx)
    vim.bo.modifiable = true
    -- :vimgrep's quickfix window display format now includes start and end column (in vim and nvim) so adding 2nd format to match that
    vim.bo.errorformat = '%f|%l col %c| %m,%f|%l col %c-%k| %m'
    vim.keymap.set(
      'n',
      '<C-s>',
      '<Cmd>cgetbuffer|set nomodified|echo "quickfix/location list updated"<CR>',
      { buffer = true, desc = 'Update quickfix/location list with changes made in quickfix window' }
    )
  end,
})

-- vim: ts=2 sts=2 sw=2 et
