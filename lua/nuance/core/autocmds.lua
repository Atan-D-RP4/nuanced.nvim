-- [[ User and Autocommands ]]

local autocmd = vim.api.nvim_create_autocmd
local utils = require 'nuance.core.utils'

vim.cmd 'cabbrev git Git'

-- One more step towards getting rid of Noice
--[[
autocmd({ 'CmdlineEnter', 'CmdlineLeave' }, {
  group = utils.augroup 'dynamic-cmdheight',
  desc = 'Dynamically adjust cmdheight based on command line activity',
  callback = function(opts)
    local cmdheight = 1
    if opts.event == 'CmdlineEnter' then
      cmdheight = 1
    elseif opts.event == 'CmdlineLeave' then
      cmdheight = 0
    end
    if vim.opt.cmdheight:get() ~= cmdheight then
      vim.opt.cmdheight = cmdheight
      vim.cmd.redrawstatus()
    end
  end,
})
--]]

autocmd('FileType', {
  pattern = { 'markdown', 'text' },
  desc = 'Use K to show dictionary definition of word under cursor',
  group = utils.augroup 'dictionary-keymap',
  callback = function()
    if vim.fn.executable 'dict' ~= 1 or vim.fn.executable 'wn' ~= 1 then
      vim.notify('Neither "dict" nor "wn" command is available for dictionary lookup', vim.log.levels.WARN)
      return
    end
    utils.map('n', 'K', function()
      local word = vim.fn.expand '<cword>'
      if word == '' then
        vim.notify('No word under cursor', vim.log.levels.WARN)
        return
      end

      local cmd
      if vim.fn.executable 'wn' == 1 then
        cmd = { 'wn', word, '-over' }
      else
        cmd = { 'dict', word }
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

autocmd({ 'BufRead', 'BufNewFile' }, {
  desc = 'Set filetype for systemd service files',
  group = utils.augroup 'set-systemd-ft',
  pattern = { '*.service', '*.socket', '*.target', '*.path', '*.timer', '*.mount', '*.automount', '*.swap', '*.slice', '*.scope' },
  callback = function()
    vim.bo.filetype = 'systemd'
  end,
})

autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = utils.augroup 'highlight-yank',
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
  group = utils.augroup 'diffcolors',
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
  group = utils.augroup 'yank-ring',
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
  group = utils.augroup 'restore-cursor',
  callback = function()
    local last_pos = vim.fn.line '\'"' > 0 and vim.fn.line '\'"' <= vim.fn.line '$'
    if vim.bo.buflisted and last_pos then
      vim.cmd 'normal! g`"'
    end
  end,
})

autocmd({ 'RecordingEnter', 'RecordingLeave' }, {
  desc = 'Notify when recording a macro',
  group = utils.augroup 'macro-notify',
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
  group = utils.augroup 'resize-splits',
  callback = function()
    vim.cmd 'tabdo wincmd ='
    vim.cmd('tabnext ' .. vim.fn.tabpagenr())
  end,
})

autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  desc = 'Check if we need to reload the file when it changed',
  group = utils.augroup 'checktime',
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd 'exec "checktime"'
    end
  end,
})

autocmd('BufWritePre', {
  desc = 'Clear trailing whitespace and empty comment lines on save',
  group = utils.augroup 'clear-whitespace-and-empty-comments',
  ---@type vim.api.keyset.create_autocmd.callback_args
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
        -- vim.cmd(cmd)
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
  group = utils.augroup 'term-management',
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
      vim.cmd [[ startinsert ]]
    end
  end,
})

autocmd('BufEnter', {
  desc = 'Disable auto comment on new line',
  group = utils.augroup 'disable-auto-comment',
  pattern = '*',
  command = [[set formatoptions-=cro]],
})

autocmd('FileType', {
  desc = 'Allow editing and reloading of quickfix window',
  group = utils.augroup('edit-quickfix', { clear = true }),
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
    utils.map('n', '<C-s>', function()
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
    utils.map('n', '<C-r>', function()
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
    utils.map('n', 'dd', function()
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

local qclose_group = utils.augroup 'close-with-q'
autocmd('FileType', {
  group = qclose_group,
  desc = 'Close miscellaneous buffers with q',
  -- stylua: ignore
  pattern = {
    'checkhealth', 'cmdwin', 'dbout', 'help', 'lspinfo', 'qf', 'query', 'startuptime', 'terminal', 'nvim-undotree', 'msg',
    'fugitive', 'fugitiveblame', 'fugitivediff', 'fugitivediffsplit', 'fugitivediffvsplit',
    'git', 'gitsigns-blame',
    'neotest-output', 'neotest-output-panel', 'neotest-summary',
    'PlenaryTestPopup', 'DiffviewFiles',
    'notify', 'trouble', 'grug-far',
    'tsplayground'
  },
  callback = function(ev)
    utils.set_close_q(ev.buf)
  end,
})

-- Terminal buffers
autocmd('TermOpen', {
  group = qclose_group,
  desc = 'Close [No Name] buffers with q',
  callback = function(ev)
    utils.set_close_q(ev.buf)
  end,
})

autocmd({ 'BufWritePre' }, {
  desc = 'Auto-create parent directory for file',
  group = utils.augroup 'auto-create-parent-dir',
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
--   group = utils.augroup 'bigfile-optimization',
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
  group = utils.augroup 'treesitter-folding',
  pattern = '*',
  callback = function(ev)
    local ft = ev.match
    vim.b.treesitter_folding_excluded = vim.tbl_contains(vim.g.treesitter_folding_exclude or {}, ft)

    vim.schedule(function()
      if vim.g.treesitter_folding_enabled and not vim.b.treesitter_folding_excluded then
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
    end)
  end,
})

vim.api.nvim_create_user_command('ToggleTreesitterFolding', function()
  vim.g.treesitter_folding_enabled = not vim.g.treesitter_folding_enabled
  local state = vim.g.treesitter_folding_enabled and 'Enabled' or 'Disabled'
  vim.notify(
    state .. ' Treesitter folding',
    state == 'Enabled' and vim.log.levels.INFO or vim.log.levels.WARN,
    { title = 'Treesitter Folding', timeout = 5000, hide_from_history = false }
  )
  vim.api.nvim_exec_autocmds('FileType', { pattern = vim.bo.filetype })
end, { nargs = 0, desc = 'Toggle Treesitter folding' })

---@param args vim.api.keyset.create_user_command.command_args
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
  group = utils.augroup 'toggle-relative-number',
  pattern = '*',
  callback = function(ev)
    if vim.bo[ev.buf].filetype:match '^snacks_' then
      return
    end
    -- Check if the event is one of the specified events or if the window is a command window
    if vim.tbl_contains({ 'WinEnter', 'BufEnter', 'FocusGained', 'CmdwinLeave' }, ev.event) then
      vim.opt_local.relativenumber = true
      vim.opt_local.number = true
      vim.opt_local.cursorline = true
    end
    if vim.tbl_contains({ 'WinLeave', 'BufLeave', 'FocusLost', 'CmdwinEnter' }, ev.event) then
      vim.opt_local.relativenumber = false
      vim.opt_local.number = false
      vim.opt_local.cursorline = false
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
