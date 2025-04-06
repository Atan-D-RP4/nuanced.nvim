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
    (vim.highlight or vim.hl).on_yank { timeout = 200, on_visual = true }
    if vim.g.cur_yank_pre then
      vim.api.nvim_win_set_cursor(0, vim.g.cur_yank_pre)
      vim.g.cur_yank_pre = nil
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
      vim.cmd 'checktime'
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
    }

    -- Check if it's a special filetype or an empty buffer
    local is_qft = vim.tbl_contains(q_fts, ft)

    local is_empty = vim.api.nvim_buf_get_name(bufnr) == '' and (ft == '' or ft == nil)

    if is_qft or is_empty then
      if is_qft then
        vim.bo[bufnr].buflisted = false
      end

      vim.keymap.set('n', 'q', function()
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
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
})

if vim.g.treesitter_lint_available == true then
  autocmd({ 'FileType', 'TextChanged', 'InsertLeave' }, {
    desc = 'Treesitter-based Diagnostics',
    pattern = '*',
    group = augroup 'treesitter-diagnostics',
    callback = vim.schedule_wrap(function()
      local bufnr = vim.api.nvim_get_current_buf()
      local excluded_filetypes = { 'rust', 'markdown', 'text' } -- Add filetypes to exclude here
      local ft = vim.bo[bufnr].filetype

      if vim.g.treesitter_diagnostics == false or vim.tbl_contains(excluded_filetypes, ft) then
        vim.diagnostic.reset(require('nuance.core.ts-diagnostics').namespace, bufnr)
        return
      end
      require('nuance.core.ts-diagnostics').diagnostics(bufnr)
    end),
  })

  vim.api.nvim_create_user_command('TSDiagnosticsToggle', function(_)
    -- Toggle the global flag
    vim.g.treesitter_diagnostics = not vim.g.treesitter_diagnostics

    local bufnr = vim.api.nvim_get_current_buf()

    -- Reset existing diagnostics
    vim.diagnostic.reset(require('nuance.core.ts-diagnostics').namespace, bufnr)

    -- If diagnostics are now enabled, run diagnostics immediately
    if vim.g.treesitter_diagnostics then
      -- Force run the diagnostics function directly
      require('nuance.core.ts-diagnostics').diagnostics(bufnr)
    end

    -- Notify the user about the current state
    local state = vim.g.treesitter_diagnostics and 'Enabled' or 'Disabled'
    vim.notify(
      state .. ' Treesitter diagnostics',
      vim.g.treesitter_diagnostics and vim.log.levels.INFO or vim.log.levels.WARN,
      { title = 'Treesitter Diagnostics', timeout = 5000, hide_from_history = false }
    )
  end, { nargs = 0, desc = 'Toggle Treesitter diagnostics' })
end

if vim.diagnostic.config().virtual_lines then
  local og_virt_text
  local og_virt_line
  autocmd({ 'CursorMoved', 'DiagnosticChanged' }, {
    desc = 'Toggle virtual lines based on diagnostics count',
    group = augroup('diagnostic_only_virtlines', {}),
    callback = function()
      if og_virt_line == nil then
        og_virt_line = vim.diagnostic.config().virtual_lines
      end

      -- ignore if virtual_lines.current_line is disabled
      if not (og_virt_line and og_virt_line.current_line) then
        if og_virt_text then
          vim.diagnostic.config { virtual_text = og_virt_text }
          og_virt_text = nil
        end
        return
      end

      if og_virt_text == nil then
        og_virt_text = vim.diagnostic.config().virtual_text
      end

      local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

      if #vim.diagnostic.get(0, { lnum = lnum }) < 2 then
        vim.diagnostic.config { virtual_text = og_virt_text }
        vim.diagnostic.config { virtual_lines = false }
      else
        vim.diagnostic.config { virtual_text = false }
        vim.diagnostic.config { virtual_lines = og_virt_line }
      end
    end,
  })
else
  autocmd('CursorHold', {
    desc = 'Toggle Diagnostic Float based on diagnostic count',
    group = augroup 'diagnostic-float',
    pattern = '*',
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      local line = vim.api.nvim_win_get_cursor(0)[1] - 1
      local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })

      if #diagnostics > 0 then
        local opts = {
          focusable = false,
          close_events = { 'CursorMoved', 'InsertEnter', 'FocusLost' },
          border = 'rounded',
          source = 'always',
          prefix = ' ',
        }
        vim.diagnostic.open_float({ border = 'rounded', source = 'if_many' }, opts)
      end
    end,
  })
end

autocmd({ 'BufEnter' }, {
  desc = 'Treesitter Folding',
  group = augroup 'treesitter-folding',
  pattern = '*',
  callback = function(e)
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

-- Define highlight groups
vim.api.nvim_command 'highlight Filepath gui=underline cterm=underline guifg=#F38BA8'

-- Match filepaths (fixed regex)
vim.cmd 'match Filepath /\\v(\\~\\/|\\.\\.\\/|\\.\\/|\\/)([^\\/ ]+\\/)*[^\\/ ]+(\\.[a-zA-Z0-9]+)*(:\\d+){0,2}/'

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
