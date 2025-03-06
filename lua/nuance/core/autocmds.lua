-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

---@param name string
---@param opts? vim.keymap.set.Opts|string
local function augroup(name, opts)
  local options = { clear = true }
  if opts then
    options = vim.tbl_extend('force', options, opts)
  end
  return vim.api.nvim_create_augroup('nuance-' .. name, options)
end

local autocmd = vim.api.nvim_create_autocmd

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = augroup 'highlight-yank',
  callback = function()
    local clip = '/mnt/c/Windows/System32/clip.exe'
    if vim.v.event.operator == 'y' then
      if vim.fn.executable(clip) == 1 then
        vim.fn.system(clip, vim.fn.getreg '0')
        if vim.g.cur_yank_pre then
          vim.api.nvim_win_set_cursor(0, vim.g.cur_yank_pre)
        end
      end
    end
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- Automatically restore the previous cursor position when entering a new buffer.
autocmd('BufWinEnter', {
  desc = 'Restore Cursor position when entering a buffer',
  group = augroup 'restore-cursor',
  callback = function()
    local last_pos = vim.fn.line '\'"' > 0 and vim.fn.line '\'"' <= vim.fn.line '$'
    if vim.bo.buflisted and last_pos then
      vim.cmd 'normal! g`"'
    end
  end,
})

-- NOTE: DO NOT NEED THIS WITH snacks.nvim in use
-- autocmd({ 'CursorMoved', 'InsertEnter' }, {
--   group = augroup 'toggle-hl-search' ,
--   callback = function(ev)
--     if ev.event == 'InsertEnter' then
--       vim.schedule(function()
--         vim.cmd 'nohlsearch'
--       end)
--     end
--     -- No bloat lua adpatation of: https://github.com/romainl/vim-cool
--     local view, rpos = vim.fn.winsaveview(), vim.fn.getpos '.'
--     -- Move the cursor to a position where (whereas in active search) pressing `n`
--     -- brings us to the original cursor position, in a forward search / that means
--     -- one column before the match, in a backward search ? we move one col forward
--     vim.cmd(string.format('silent! keepjumps go%s', (vim.fn.line2byte(view.lnum) + view.col + 1 - (vim.v.searchforward == 1 and 2 or 0))))
--     -- Attempt to goto next match, if we're in an active search cursor position
--     -- should be equal to original cursor position
--     local ok, _ = pcall(vim.cmd, 'silent! keepjumps norm! n')
--     local insearch = ok and (function()
--       local npos = vim.fn.getpos '.'
--       return npos[2] == rpos[2] and npos[3] == rpos[3]
--     end)()
--     -- restore original view and position
--     vim.fn.winrestview(view)
--     if not insearch then
--       vim.schedule(function()
--         vim.cmd 'nohlsearch'
--       end)
--     end
--   end,
-- })
--
autocmd({ 'RecordingEnter', 'RecordingLeave' }, {
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

autocmd('VimResized', {
  desc = 'Resize splits when resizing the window',
  group = augroup 'resize-splits',
  callback = function()
    vim.cmd 'wincmd ='
  end,
})

-- Clear trailing whitespace on save
autocmd('BufWritePre', {
  desc = 'Clear trailing whitespace on save',
  group = augroup 'clear-trailing-whitespace',
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd [[keeppatterns %s/\s\+$//e]]
    vim.fn.winrestview(save)
  end,
})

-- Close buffer if the terminal is closed
autocmd({ 'TermClose', 'TermOpen' }, {
  desc = 'Terminal Buffer Management',
  group = augroup 'term-management',
  pattern = '*',
  callback = function(ev)
    if ev.event == 'TermClose' then
      vim.schedule(function()
        if (vim.bo.buftype == 'terminal' or vim.bo.filetype == 'lua') and vim.v.shell_error == 0 then
          vim.cmd('bdelete! ' .. vim.fn.expand '<abuf>')
        end
      end)
    elseif ev.event == 'TermOpen' then
      vim.opt.relativenumber = false
      vim.opt.spell = false
      vim.opt.number = false
    end
  end,
})

-- don't auto comment new line
autocmd('BufEnter', { command = [[set formatoptions-=cro]] })

-- NOTE: (This works but needs to be improved for Cmdwin)
-- Toggle relative number on the basis of mode
-- local number_toggle_group = autocmd('NumberToggle', { clear = true })
-- autocmd({ 'BufEnter', 'FocusGained', 'InsertLeave' }, {
--   pattern = '*',
--   callback = function()
--     vim.wo.relativenumber = true
--     vim.wo.number = true
--   end,
--   group = number_toggle_group,
-- })
-- autocmd({ 'BufLeave', 'FocusLost', 'InsertEnter' }, {
--   pattern = '*',
--   callback = function()
--     vim.wo.relativenumber = false
--     vim.wo.number = false
--   end,
--   group = number_toggle_group,
-- })

-- NOTE: Originally tried to put this in FileType event autocmd but it is apparently
-- too early for `set modifiable` to take effect
autocmd('BufWinEnter', {
  group = augroup 'edit-quickfix',
  desc = 'allow updating quickfix window',
  pattern = 'quickfix',
  callback = function()
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

autocmd('FileType', {
  group = augroup 'close-with-q',
  pattern = {
    'PlenaryTestPopup',
    'checkhealth',
    '',
    'dbout',
    'gitsigns-blame',
    'query',
    'grug-far',
    'help',
    'lspinfo',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    'notify',
    'git',
    'fugitive',
    'fugitiveblame',
    'fugitivediff',
    'fugitivediffsplit',
    'fugitivediffvsplit',
    'qf',
    'spectre_panel',
    'startuptime',
    'tsplayground',
  },
  ---@param event vim.api.keyset.create_autocmd.callback_args
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set('n', 'q', function()
        vim.cmd 'close'
        pcall(autocmd, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = 'Quit buffer',
      })
    end)
  end,
})

autocmd({ 'BufWritePre' }, {
  group = augroup 'auto-create-dir',
  callback = function(event)
    if event.match:match '^%w%w+:[\\/][\\/]' then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
})

vim.api.nvim_create_autocmd({ 'FileType', 'TextChanged', 'InsertLeave' }, {
  desc = 'Treesitter-based Diagnostics',
  pattern = '*',
  group = vim.api.nvim_create_augroup('nuance-treesitter-diagnostics', { clear = true }),
  ---@param event vim.api.keyset.create_autocmd.callback_args
  callback = vim.schedule_wrap(function(event)
    if vim.g.treesitter_diagnostics == false then
      vim.diagnostic.reset(require('nuance.core.ts-diagnostics').namespace, event.buf)
      return
    end
    require('nuance.core.ts-diagnostics').diagnostics(event)
  end),
})

vim.api.nvim_create_user_command('TSDiagnosticsToggle', function(_)
  vim.g.treesitter_diagnostics = not vim.g.treesitter_diagnostics
end, { nargs = 0 })

-- Define highlight groups
vim.api.nvim_command 'highlight Filepath gui=underline cterm=underline guifg=#F38BA8'

-- Match filepaths (fixed regex)
vim.cmd 'match Filepath /\\v(\\~\\/|\\.\\.\\/|\\.\\/|\\/)([^\\/ ]+\\/)*[^\\/ ]+(\\.[a-zA-Z0-9]+)*(:\\d+){0,2}/'

-- local ns = vim.api.nvim_create_namespace 'filepath_highlighter'
--
-- local function highlight_filepaths(bufnr)
--   vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
--   local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
--   local pattern = "(/[%w%._%-]+)+"
--
--   for lnum, line in ipairs(content) do
--     local start = 0
--     while true do
--       local start_idx, end_idx = line:find(pattern, start)
--       if not start_idx then
--         break
--       end
--
--       vim.g.filepath_highlighter = ns
--       vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, start_idx - 1, {
--         end_row = lnum - 1,
--         end_col = end_idx,
--         hl_group = 'Filepath',
--         priority = 100,
--       })
--
--       start = end_idx + 1
--     end
--   end
-- end
--
-- -- Attach to buffers
-- vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'InsertLeave' }, {
--   callback = function(args)
--     vim.print(vim.api.nvim_buf_get_extmarks(args.buf, ns, 0, -1, { details = true }))
--     vim.schedule(function()
--       highlight_filepaths(args.buf)
--     end)
--   end,
--   pattern = '*',
-- })

-- vim: ts=2 sts=2 sw=2 et
