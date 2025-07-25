-- [[ Basic Autocommands ]]

local augroup = require('nuance.core.utils').augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight when yanking (copying) text
autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = augroup 'highlight-yank',
  callback = function()
    (vim.highlight or vim.hl).on_yank { timeout = 200, on_visual = true }
    if vim.g.cur_yank_pre then
      vim.api.nvim_win_set_cursor(0, vim.g.cur_yank_pre)
      vim.g.cur_yank_pre = nil
    end
  end,
})

vim.api.nvim_create_autocmd('Colorscheme', {
  desc = 'Set custom colors for diff highlighting',
  group = augroup('diffcolors', { clear = true }),
  callback = function()
    if vim.o.background == 'dark' then
      vim.api.nvim_set_hl(0, 'DiffAdd', { bold = true, fg = 'none', bg = '#2e4b2e' })
      vim.api.nvim_set_hl(0, 'DiffDelete', { bold = true, fg = 'none', bg = '#4c1e15' })
      vim.api.nvim_set_hl(0, 'DiffChange', { bold = true, fg = 'none', bg = '#45565c' })
      vim.api.nvim_set_hl(0, 'DiffText', { bold = true, fg = 'none', bg = '#996d74' })
    else
      vim.api.nvim_set_hl(0, 'DiffAdd', { bold = true, fg = 'none', bg = 'palegreen' })
      vim.api.nvim_set_hl(0, 'DiffDelete', { bold = true, fg = 'none', bg = 'tomato' })
      vim.api.nvim_set_hl(0, 'DiffChange', { bold = true, fg = 'none', bg = 'lightblue' })
      vim.api.nvim_set_hl(0, 'DiffText', { bold = true, fg = 'none', bg = 'lightpink' })
    end
  end,
})

-- Create autocmd for TextYankPost event
autocmd('TextYankPost', {
  group = augroup 'yank-ring',
  callback = function()
    local event = vim.v.event
    if event.operator == 'y' then
      for i = 9, 1, -1 do
        vim.fn.setreg(tostring(i), vim.fn.getreg(tostring(i - 1)))
      end
    end
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

autocmd({ 'RecordingEnter', 'RecordingLeave' }, {
  desc = 'Notify when recording a macro',
  group = augroup 'macro-notify',
  callback = function(ev)
    local msg
    if ev.event == 'RecordingEnter' then
      msg = 'Recording to register @'
    else
      msg = 'Recorded to register @'
    end
    vim.notify(msg .. vim.fn.reg_recording(), vim.log.levels.INFO, { title = 'Macro', timeout = 5000, hide_from_history = false })
  end,
})

autocmd('VimResized', {
  desc = 'Resize splits when resizing the window',
  group = augroup 'resize-splits',
  callback = function()
    vim.cmd 'tabdo wincmd ='
    vim.cmd('tabnext ' .. vim.fn.tabpagenr())
  end,
})

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  desc = 'Check if we need to reload the file when it changed',
  group = augroup 'checktime',
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd 'exec "checktime"'
    end
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
autocmd('BufEnter', {
  desc = 'Disable auto comment on new line',
  group = augroup 'disable-auto-comment',
  pattern = '*',
  command = [[set formatoptions-=cro]],
})

-- NOTE: Originally tried to put this in FileType event autocmd but it is apparently
-- too early for `set modifiable` to take effect
autocmd('BufWinEnter', {
  desc = 'Allow editing of quickfix window',
  group = augroup 'edit-quickfix',
  pattern = 'quickfix',
  callback = function()
    vim.bo.modifiable = true
    vim.bo.buflisted = false
    -- :vimgrep's quickfix window display format now includes start and end column (in vim and nvim) so adding 2nd format to match that
    vim.bo.errorformat = '%f|%l col %c| %m,%f|%l col %c-%k| %m'

    -- Enhanced keymap for updating quickfix
    vim.keymap.set('n', '<C-s>', function()
      vim.cmd [[ exec 'cgetbuffer' ]]
      vim.bo.modified = false
      vim.notify('Quickfix/location list updated', vim.log.levels.INFO, {
        title = 'Quickfix',
        timeout = 2000,
      })
    end, { buffer = true, desc = 'Update quickfix/location list with changes made in quickfix window' })

    -- Additional useful keymaps for quickfix editing
    vim.keymap.set('n', '<C-r>', function()
      vim.cmd [[ exec "edit!" ]]
      vim.notify('Quickfix list reloaded', vim.log.levels.INFO, {
        title = 'Quickfix',
        timeout = 2000,
      })
    end, { buffer = true, desc = 'Reload quickfix list' })

    -- Quick navigation keymaps
    vim.keymap.set('n', 'dd', function()
      local line = vim.fn.line '.'
      vim.cmd [[ exec 'delete' ]]
      if vim.fn.line '$' == 1 then
        vim.cmd [[ exec 'cclose' ]]
      end
    end, { buffer = true, desc = 'Delete quickfix entry' })
  end,
})

autocmd('BufEnter', {
  desc = 'Close miscellaneous buffers with q',
  group = augroup 'close-with-q',
  callback = function(event)
    local bufnr = event.buf
    local ft = vim.bo[bufnr].filetype

    local q_fts = {
      '',
      'PlenaryTestPopup',
      'checkhealth',
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
      'startuptime',
      'tsplayground',
      -- Cmdline window
      'cmdwin',
    }

    -- Check if it's a special filetype or an empty buffer
    local is_qft = vim.tbl_contains(q_fts, ft)

    local is_empty = vim.api.nvim_buf_get_name(bufnr) == '' and (ft == '' or ft == nil)

    if is_qft or is_empty then
      if is_qft then
        vim.bo[bufnr].buflisted = false
      end

      vim.keymap.set('n', 'q', function()
        if vim.fn.getcmdwintype() ~= '' then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, false, true), 'n', false)
          return
        end

        pcall(vim.api.nvim_exec2, 'close', {})

        local has_snacks, snacks = pcall(require, 'snacks')
        if has_snacks == false then
          vim.print 'Fallback to default forced buffer deletion'
          pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
        else
          snacks.bufdelete.delete(bufnr)
        end
      end, {
        buffer = bufnr,
        silent = true,
        desc = 'Quit buffer',
      })
    end
  end,
})

autocmd({ 'BufWritePre' }, {
  desc = 'Auto-create directory for file',
  group = augroup 'auto-create-dir',
  callback = function(event)
    if event.match:match '^%w%w+:[\\/][\\/]' then
      return
    end
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
})

-- ref: https://vi.stackexchange.com/a/169/15292
autocmd('BufReadPre', {
  group = augroup 'bigfile-optimization',
  pattern = '*',
  desc = 'Optimize for large file',
  callback = function(ev)
    local file_size_limit = 524288 -- 0.5MB
    local f = ev.file

    if vim.fn.getfsize(f) > file_size_limit or vim.fn.getfsize(f) == -2 then
      vim.o.eventignore = 'all'

      -- show ruler
      vim.o.ruler = true

      --  turning off relative number helps a lot
      vim.wo.relativenumber = false
      vim.wo.number = false

      vim.bo.swapfile = false
      vim.bo.bufhidden = 'unload'
      vim.bo.undolevels = -1
    end
  end,
})

autocmd({ 'BufEnter' }, {
  desc = 'Treesitter Folding',
  group = augroup 'treesitter-folding',
  pattern = '*',
  callback = function()
    vim.defer_fn(function()
      if vim.g.treesitter_folding_enabled then
        vim.opt.foldenable = true
        vim.opt.foldlevel = 99
        vim.opt.foldmethod = 'expr'
      else
        vim.opt.foldenable = false
        vim.opt.foldlevel = 0
        vim.opt.foldmethod = 'manual'
      end
    end, 100)
  end,
})

autocmd('FileType', {
  desc = 'Disable Treesitter folding for certain filetypes',
  group = augroup 'disable-treesitter-folding',
  pattern = { 'markdown', 'text', 'gitcommit', 'gitrebase', 'help' }, -- Add filetypes to exclude here
  callback = function()
    vim.g.treesitter_folding_enabled = false
    vim.opt.foldenable = false
    vim.opt.foldlevel = 0
    vim.opt.foldmethod = 'manual'
  end,
})

vim.api.nvim_create_user_command('TSFoldToggle', function(_)
  vim.g.treesitter_folding_enabled = not vim.g.treesitter_folding_enabled
  local state = vim.g.treesitter_folding_enabled and 'Enabled' or 'Disabled'
  vim.notify(
    state .. ' Treesitter folding',
    state == 'Enabled' and vim.log.levels.INFO or vim.log.levels.WARN,
    { title = 'Treesitter Folding', timeout = 5000, hide_from_history = false }
  )
  if vim.g.treesitter_folding_enabled then
    vim.opt.foldenable = true
    vim.opt.foldlevel = 99
    vim.opt.foldmethod = 'expr'
  else
    vim.opt.foldenable = false
    vim.opt.foldlevel = 0
    vim.opt.foldmethod = 'manual'
    vim.cmd 'normal! zE' -- Recalculate folds
  end
end, { nargs = 0, desc = 'Toggle Treesitter folding' })

vim.api.nvim_create_user_command('SearchEngineQuery', function(args)
  local engines = {
    google = { prompt = ' Google: ', url = 'https://www.google.com/search?q=' },
    ddg = { prompt = ' DuckDuckGo: ', url = 'https://duckduckgo.com/?q=' },
  }

  local selected_engine = engines[args.args == '' and 'ddg' or args.args]
  local query = ''

  -- Check if a range is specified (visual selection)
  if args.range > 0 then
    -- Get the selected text
    local start_line, start_col = unpack(vim.api.nvim_buf_get_mark(0, '<'))
    local end_line, end_col = unpack(vim.api.nvim_buf_get_mark(0, '>'))

    -- Make end_col inclusive to exclusive
    end_col = end_col + 1

    -- Get the selected text
    local lines = vim.api.nvim_buf_get_text(0, start_line - 1, start_col, end_line - 1, end_col, {})

    query = table.concat(lines, ' ')
  else
    -- No selection, use input or current word
    local input = vim.fn.input(selected_engine.prompt)
    local response = not (input == nil or input == '')

    if args.fargs[1] == 'ft' then
      query = vim.bo.filetype
    end

    if response then
      query = query .. ' ' .. input
    else
      query = query .. ' ' .. vim.fn.expand '<cword>'
    end
  end

  -- Encode the query for URL
  query = vim.fn.shellescape(query)

  -- Open the URL
  vim.ui.open(selected_engine.url .. query)
end, { nargs = '?', range = true, desc = 'Search using a specified engine' })

autocmd({ 'WinEnter', 'BufEnter', 'FocusGained', 'WinLeave', 'BufLeave', 'FocusLost', 'CmdwinEnter' }, {
  group = augroup('NumberToggle', { clear = true }),
  pattern = '*',
  callback = function(ev)
    if vim.bo[ev.buf].filetype:match '^snacks_' then
      return
    end
    -- Check if the event is one of the specified events or if the window is a command window
    if vim.tbl_contains({ 'WinEnter', 'BufEnter', 'FocusGained', 'CmdwinLeave' }, ev.event) then
      vim.wo.relativenumber = true
      vim.wo.number = true
    end
    if vim.tbl_contains({ 'WinLeave', 'BufLeave', 'FocusLost', 'CmdwinEnter' }, ev.event) then
      vim.wo.relativenumber = false
      vim.wo.number = false
    end
  end,
})

vim.api.nvim_create_user_command('ToggleTransparency', function()
  vim.g.transparency = vim.g.transparency or {
    enabled = false,
    hl1 = {},
    hl2 = {},
    hl3 = {},
  }

  if not vim.g.transparency.enabled then
    local transparency = vim.g.transparency or {}
    transparency.enabled = true

    transparency.hl1 = vim.api.nvim_get_hl(0, { name = 'Normal' })
    transparency.hl2 = vim.api.nvim_get_hl(0, { name = 'NormalNC' })
    transparency.hl3 = vim.api.nvim_get_hl(0, { name = 'EndOfBuffer' })
    vim.g.transparency = transparency

    vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'NormalNC', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = 'none' })
  else
    local transparency = vim.g.transparency or {}
    vim.api.nvim_set_hl(0, 'Normal', vim.g.transparency.hl1)
    vim.api.nvim_set_hl(0, 'NormalNC', vim.g.transparency.hl2)
    vim.api.nvim_set_hl(0, 'EndOfBuffer', vim.g.transparency.hl3)
    transparency = {
      enabled = false,
      hl1 = {},
      hl2 = {},
      hl3 = {},
    }
    vim.g.transparency = transparency
  end

  vim.print(vim.g.transparency)
end, {
  nargs = 0,
  desc = 'Toggle Transparency',
})

vim.api.nvim_create_user_command('ToggleClipSync', function()
  local clipboard = vim.o.clipboard
  if clipboard:find 'unnamed' then
    vim.opt.clipboard:remove { 'unnamed', 'unnamedplus' }
    vim.notify('OS clipboard sync disabled', vim.log.levels.INFO, { title = 'Clipboard' })
  else
    vim.opt.clipboard:append { 'unnamed', 'unnamedplus' }
    vim.notify('OS clipboard sync enabled', vim.log.levels.INFO, { title = 'Clipboard' })
  end
end, {
  nargs = 0,
  desc = 'Toggle OS clipboard',
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

-- Define highlight groups
-- vim.api.nvim_command 'highlight Filepath gui=underline cterm=underline guifg=#F38BA8'

-- Match filepaths (fixed regex)
-- vim.cmd 'match Filepath /\\v(\\~\\/|\\.\\.\\/|\\.\\/|\\/)([^\\/ ]+\\/)*[^\\/ ]+(\\.[a-zA-Z0-9]+)*(:\\d+){0,2}/'

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
