-- [[ Basic Autocommands ]]

local augroup = require('nuance.core.utils').augroup
local autocmd = vim.api.nvim_create_autocmd

autocmd('FileType', {
  pattern = { 'markdown', 'text' },
  desc = 'Use K to show dictionary definition of word under cursor',
  group = augroup 'dictionary-keymap',
  callback = function()
    if vim.executable 'wn' ~= 1 then
      return
    end
    vim.keymap.set('n', 'K', function()
      local word = vim.fn.expand '<cword>'
      if word == '' then
        vim.notify('No word under cursor', vim.log.levels.WARN)
        return
      end

      local cmd
      if vim.fn.executable 'wn' == 1 then
        cmd = { 'wn', word, '-over' }
      else
        vim.notify('No dictionary program found (install `dict` or `wordnet`)', vim.log.levels.ERROR)
        return
      end

      -- Run asynchronously and show in LSP-style hover
      vim.system(cmd, { text = true }, function(res)
        if not res.stdout or res.stdout == '' then
          vim.schedule(function()
            vim.notify("No definition found for '" .. word .. "'", vim.log.levels.INFO)
          end)
          return
        end

        vim.schedule(function()
          vim.lsp.util.open_floating_preview(vim.split(res.stdout, '\n'), 'markdown', {
            border = 'rounded',
            focusable = true,
            title = 'Definition: ' .. word,
          })
        end)
      end)
    end, { buffer = true, desc = 'Show dictionary definition' })
  end,
})

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

autocmd('Colorscheme', {
  desc = 'Set custom colors for diff highlighting',
  group = augroup 'diffcolors',
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

autocmd({ 'TextYankPost' }, {
  group = augroup 'yank-ring',
  pattern = '*', -- apply for all buffers / files
  desc = 'Maintain ring of recent yanks or deletes in numbered registers 1-9',
  callback = function()
    -- ev is a table with info: ev.operator, ev.regname, ev.regtype, ev.buf, etc :contentReference[oaicite:1]{index=1}
    local ev = vim.v.event

    -- Filter: only handle operator "y" (yank) or "d" (delete)
    -- and the default register (i.e., no explicit regname)
    if ev.operator ~= 'y' and ev.operator ~= 'd' and ev.regname ~= '' then
      return
    end

    -- Optionally, skip huge yanks/deletes: for example if register 0 contents > X lines
    local latest = vim.fn.getreg '0'
    local max_lines = 1000 -- for example: skip if too many lines
    local newline_count = #vim.fn.split(latest, '\n')
    if newline_count > max_lines then
      return
    end

    -- Slide the registers: 9 ← 8 ← … ← 1 ← 0
    for i = 9, 1, -1 do
      local from = tostring(i - 1)
      local to = tostring(i)
      local text = vim.fn.getreg(from)
      local regtype = vim.fn.getregtype(from)
      vim.fn.setreg(to, text, regtype)
    end
  end,
})

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

autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  desc = 'Check if we need to reload the file when it changed',
  group = augroup 'checktime',
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd 'exec "checktime"'
    end
  end,
})

autocmd('BufWritePre', {
  desc = 'Clear trailing whitespace and empty comment lines on save',
  group = augroup 'clear-whitespace-and-empty-comments',
  ---@type vim.api.create_autocmd.callback.args
  callback = function(ev)
    local save = vim.fn.winsaveview()

    local ft = vim.bo[ev.buf].filetype
    local cs = vim.bo.commentstring or ''

    -- Skip files with no commentstring or excluded filetypes
    local skip_filetypes = vim.g.clear_whitespace_empty_comments_exclude or {}
    vim.tbl_extend('keep', skip_filetypes, { 'oil' })
    if not vim.tbl_contains(skip_filetypes, ft) and cs ~= '' then
      -- Extract prefix/suffix from commentstring pattern like "-- %s" or "<!-- %s -->"
      local prefix, suffix = cs:match '^(.-)%%s(.-)$'
      if prefix then
        -- Escape for Vim regex safely
        local function vim_escape(s)
          return s
            :gsub('([/\\~])', '\\%1') -- escape delimiter and escape chars
            :gsub('([%[%]%^%$%*%+%?%.])', '\\%1')
        end

        prefix = vim_escape(vim.trim(prefix))
        suffix = vim_escape(vim.trim(suffix))

        -- Construct substitution depending on comment style
        local cmd
        if suffix == '' then
          -- e.g. "--", "#", "//"
          cmd = ([[keeppatterns %%s/\v^\s*%s\s*\n/\r/e]]):format(prefix)
        else
          -- e.g. "<!-- -->", "{- -}", etc.
          cmd = ([[keeppatterns %%s/^\s*%s\s*%s\s*\n/\r/e]]):format(prefix, suffix)
        end

        -- Execute substitution
        vim.cmd(cmd)
      end
    end

    -- Remove trailing whitespace after comment cleanup
    vim.cmd [[keeppatterns %s/\s\+$//e]]

    vim.fn.winrestview(save)
  end,
})

-- Close buffer if the terminal is closed
autocmd({ 'TermClose', 'TermOpen' }, {
  desc = 'Close terminal buffer on exit and disable line numbers in terminal',
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

autocmd('BufEnter', {
  desc = 'Disable auto comment on new line',
  group = augroup 'disable-auto-comment',
  pattern = '*',
  command = [[set formatoptions-=cro]],
})

autocmd('FileType', {
  desc = 'Allow editing and reloading of quickfix window',
  group = augroup('edit-quickfix', { clear = true }),
  pattern = 'qf',
  callback = function()
    vim.bo.modifiable = true
    vim.bo.buflisted = false

    -- Handle both legacy and modern quickfix formats (with column ranges)
    vim.bo.errorformat = table.concat({
      '%f|%l col %c| %m',
      '%f|%l col %c-%k| %m',
    }, ',')

    -- Update quickfix list after editing entries
    vim.keymap.set('n', '<C-s>', function()
      if vim.bo.modified then
        vim.cmd 'cgetbuffer'
        vim.bo.modified = false
        vim.notify('Quickfix/location list updated', vim.log.levels.INFO, {
          title = 'Quickfix',
          timeout = 1500,
        })
      else
        vim.notify('No changes to update', vim.log.levels.WARN, {
          title = 'Quickfix',
          timeout = 1000,
        })
      end
    end, { buffer = true, desc = 'Update quickfix/location list from buffer' })

    -- Proper reload: repopulate quickfix from the previous command (not just :edit!)
    vim.keymap.set('n', '<C-r>', function()
      local qf = vim.fn.getqflist { title = 0 }
      local title = qf.title or ''
      if title:match '^vimgrep' or title:match '^grep' then
        -- Re-run the same vimgrep command if available
        vim.cmd [[ exec "cexpr []" ]] -- clear
        vim.cmd('silent ' .. title)
        vim.cmd [[ exec "copen" ]]
        vim.notify('Quickfix list reloaded from previous vimgrep', vim.log.levels.INFO, {
          title = 'Quickfix',
          timeout = 1500,
        })
      else
        -- Fallback: reload buffer content into quickfix
        vim.cmd 'cgetbuffer'
        vim.notify('Quickfix list reloaded from buffer', vim.log.levels.INFO, {
          title = 'Quickfix',
          timeout = 1500,
        })
      end
    end, { buffer = true, desc = 'Reload quickfix list (re-run vimgrep or buffer)' })

    -- Smart deletion
    vim.keymap.set('n', 'dd', function()
      local line = vim.fn.line '.'
      vim.cmd [[ exec "delete" ]]
      if vim.fn.line '$' == 1 then
        vim.cmd [[ exec "cclose" ]]
      else
        vim.cmd(('cgetbuffer | call cursor(%d, 1)'):format(math.max(1, line)))
      end
    end, { buffer = true, desc = 'Delete quickfix entry' })
  end,
})

autocmd('FileType', {
  group = augroup 'close-with-q',
  desc = 'Close miscellaneous buffers with q',
  -- stylua: ignore
  pattern = {
    'checkhealth', 'cmdwin', 'dbout', 'help', 'lspinfo', 'qf', 'query', 'startuptime',
    'fugitive', 'fugitiveblame', 'fugitivediff', 'fugitivediffsplit', 'fugitivediffvsplit',
    'git', 'gitsigns-blame',
    'neotest-output', 'neotest-output-panel', 'neotest-summary',
    'PlenaryTestPopup', 'DiffviewFiles',
    'notify', 'trouble', 'grug-far',
    'tsplayground',
  },
  callback = function(args)
    local bufnr = args.buf

    -- Mark as unlisted if needed
    vim.bo[bufnr].buflisted = false

    -- Set buffer-local keymap: q to close
    vim.keymap.set('n', 'q', function()
      if vim.fn.getcmdwintype() ~= '' then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, false, true), 'n', false)
        return
      end
      pcall(vim.cmd.close)

      if Snacks and Snacks.bufdelete then
        pcall(Snacks.bufdelete, bufnr)
      else
        pcall(require('nuance.core.utils').safe_buf_delete, bufnr)
      end
    end, {
      buffer = bufnr,
      silent = true,
      desc = 'Quit buffer',
    })
  end,
})

autocmd({ 'BufWritePre' }, {
  desc = 'Auto-create parent directory for file',
  group = augroup 'auto-create-parent-dir',
  callback = function(event)
    local bufname = vim.api.nvim_buf_get_name(event.buf)
    if bufname:match '^oil://' then
      return
    end
    local dir = vim.fn.expand '<afile>:p:h'
    -- if vim.fn.isdirectory(dir) == 0 then
    --   vim.fn.mkdir(dir, 'p')
    -- end
    if vim.uv.fs_stat(dir) == nil then
      vim.uv.fs_mkdir(dir, 493) -- 0755 in decimal
    end
  end,
})

-- ref: https://vi.stackexchange.com/a/169/15292
-- autocmd('BufReadPre', {
--   group = augroup 'bigfile-optimization',
--   pattern = '*',
--   desc = 'Optimize for large file',
--   callback = function(ev)
--     local file_size_limit = 524288 -- 0.5MB
--     local f = ev.file

--     if vim.fn.getfsize(f) > file_size_limit or vim.fn.getfsize(f) == -2 then
--       vim.o.eventignore = 'all'

--       -- show ruler
--       vim.bo.ruler = true

--       --  turning off relative number helps a lot
--       vim.wo.relativenumber = false
--       vim.wo.number = false

--       vim.bo.swapfile = false
--       vim.bo.bufhidden = 'unload'
--       vim.bo.undolevels = -1
--       vim.notify('Large file detected, optimizations applied', vim.log.levels.WARN, {
--         title = 'Big File',
--         timeout = 5000,
--       })
--     end
--   end,
-- })

autocmd({ 'FileType' }, {
  desc = 'Treesitter Folding',
  group = augroup 'treesitter-folding',
  pattern = '*',
  callback = function(ev)
    local ft = ev.match
    local skip_filetypes = vim.g.treesitter_folding_exclude or {}
    vim.tbl_extend('keep', skip_filetypes, { 'markdown', 'text', 'gitcommit', 'gitrebase', 'help' })
    vim.defer_fn(function()
      if vim.g.treesitter_folding_enabled and not vim.tbl_contains(skip_filetypes, ft) then
        vim.opt.foldenable = true
        vim.opt.foldlevel = 99
        vim.opt.foldmethod = 'expr'
      else
        vim.opt.foldenable = false
        vim.opt.foldlevel = 0
        vim.opt.foldmethod = 'manual'
      end
      -- Close all folds initially
      -- vim.cmd 'normal! zM'
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

-- autocmd BufNewFile,BufRead *.service* set ft=systemd
autocmd({ 'BufRead', 'BufNewFile' }, {
  desc = 'Set filetype for systemd service files',
  group = augroup 'set-systemd-ft',
  pattern = { '*.service', '*.socket', '*.target', '*.path', '*.timer', '*.mount', '*.automount', '*.swap', '*.slice', '*.scope' },
  callback = function()
    vim.bo.filetype = 'systemd'
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

---@param args vim.api.keyset.user_command.callback_opts
vim.api.nvim_create_user_command('SearchEngineQuery', function(args)
  local engines = {
    google = { prompt = ' Google: ', url = 'https://www.google.com/search?q=' },
    ddg = { prompt = ' DuckDuckGo: ', url = 'https://duckduckgo.com/?q=' },
  }

  local selected_engine = engines['ddg']
  if args.fargs[1] and engines[args.fargs[1]] then
    selected_engine = engines[args.fargs[1]]
  end
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
    if selected_engine == nil then
      selected_engine = engines['ddg']
    end
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
  group = augroup 'toggle-relative-number',
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
  local transparency = vim.g.transparency or { enabled = false, hl1 = {}, hl2 = {}, hl3 = {} }
  if transparency.enabled then
    vim.api.nvim_set_hl(0, 'Normal', transparency.hl1)
    vim.api.nvim_set_hl(0, 'NormalNC', transparency.hl2)
    vim.api.nvim_set_hl(0, 'EndOfBuffer', transparency.hl3)
    vim.g.transparency = { enabled = false, hl1 = {}, hl2 = {}, hl3 = {} }
  else
    transparency.hl1 = vim.api.nvim_get_hl(0, { name = 'Normal' })
    transparency.hl2 = vim.api.nvim_get_hl(0, { name = 'NormalNC' })
    transparency.hl3 = vim.api.nvim_get_hl(0, { name = 'EndOfBuffer' })
    vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'NormalNC', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = 'none' })
    transparency.enabled = true
    vim.g.transparency = transparency
  end
end, {
  nargs = 0,
  desc = 'Toggle Transparency',
})

vim.api.nvim_create_user_command('ToggleClipSync', function()
  if vim.o.clipboard:find 'unnamed' then
    vim.opt.clipboard = vim.opt.clipboard - { 'unnamed', 'unnamedplus' }
    vim.notify('OS clipboard sync disabled', vim.log.levels.INFO, { title = 'Clipboard' })
  else
    vim.opt.clipboard = vim.opt.clipboard + { 'unnamed', 'unnamedplus' }
    vim.notify('OS clipboard sync enabled', vim.log.levels.INFO, { title = 'Clipboard' })
  end
end, {
  nargs = 0,
  desc = 'Toggle OS clipboard',
})

-- vim: ts=2 sts=2 sw=2 et
