local M = {}

M.set_close_q = function(bufnr)
  vim.keymap.set('n', 'q', function()
    if vim.fn.getcmdwintype() ~= '' then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, false, true), 'n', false)
      return
    end

    pcall(vim.cmd.close)

    if Snacks ~= nil and Snacks.bufdelete ~= nil then
      pcall(Snacks.bufdelete, bufnr)
    else
      pcall(require('nuance.core.utils').safe_buf_delete, bufnr)
    end
  end, {
    buffer = bufnr,
    silent = true,
    desc = 'Quit buffer',
  })
end

---@param bufnr integer
function M.safe_buf_delete(bufnr)
  if vim.bo[bufnr].modified then
    local cond = vim.fn.confirm('Save changes to "' .. vim.api.nvim_buf_get_name(bufnr) .. '"?', '&Yes\n&No\n&Cancel', 3)
    if cond == 1 then
      vim.cmd [[ exec 'update' ]]
    elseif cond == 3 then
      return
    end
  end
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

---@param name string
---@param opts? vim.keymap.set.Opts|string
function M.augroup(name, opts)
  local options = { clear = true }
  if opts then
    options = vim.tbl_extend('force', options, opts)
  end
  return vim.api.nvim_create_augroup('nuance-' .. name, options)
end

---@param modes string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param opts? table          Optional parameters. If {buffer = 0}, checks buffer-local mappings.
---@return boolean
function M.is_key_mapped(modes, lhs, opts)
  -- Normalize modes to a list if it's a single string
  if type(modes) == 'string' then
    modes = { modes }
  end

  -- Get the leader key and expand it to its notation form
  local leader = vim.g.mapleader
  if leader ~= nil then
    -- Convert the leader character to its key notation (e.g., '\r' -> '<CR>')
    local leader_notation = vim.api.nvim_replace_termcodes(leader, true, true, true)
    leader_notation = vim.fn.keytrans(leader_notation)
    -- Replace <leader> with the actual leader key notation
    lhs = lhs:gsub('<[Ll][Ee][Aa][Dd][Ee][Rr]>', leader_notation)
  end

  -- Expand terminal codes like <CR>, <C-q>, etc.
  local expanded_lhs = vim.api.nvim_replace_termcodes(lhs, true, true, true)

  local buffer = opts and opts.buffer or nil

  for _, mode in ipairs(modes) do
    local mappings
    if buffer then
      -- Check buffer-local mappings
      mappings = vim.api.nvim_buf_get_keymap(buffer, mode)
    else
      -- Check global mappings
      mappings = vim.api.nvim_get_keymap(mode)
    end

    for _, map in pairs(mappings) do
      -- Compare both the original lhs and expanded version
      -- because maps can be stored in either form depending on how they were set
      if map.lhs == lhs or map.lhs == expanded_lhs then
        return true
      end
    end
  end

  return false
end

---@param modes string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param opts? table          Optional parameters. If {buffer = 0}, unmaps buffer-local mappings.
function M.unmap(modes, lhs, opts)
  -- Normalize modes to a list if it's a single string
  if type(modes) == 'string' then
    modes = { modes }
  end

  local buffer = opts and opts.buffer or nil

  -- Delete existing mappings for all specified modes
  for _, mode in ipairs(modes) do
    -- Try to delete the mapping, ignoring errors if it doesn't exist
    local del_opts = buffer and { buffer = buffer } or {}
    pcall(vim.keymap.del, mode, lhs, del_opts)
  end
end

--- An abstraction over |nvim_set_keymap()| that unmaps the key before setting it.
---@param modes string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts|string
function M.map(modes, lhs, rhs, opts)
  -- Extract unmap opts from keymap opts if buffer is specified
  local unmap_opts = nil
  if opts and type(opts) == 'table' and opts.buffer then
    unmap_opts = { buffer = opts.buffer }
  end

  M.unmap(modes, lhs, unmap_opts)

  -- Set new mapping
  local options = { noremap = true, silent = true }
  if opts then
    if type(opts) == 'string' then
      opts = { desc = opts }
    end
    options = vim.tbl_extend('force', options, opts)
  end

  local suc, res = pcall(vim.keymap.set, modes, lhs, rhs, options)
  if not suc then
    vim.notify('Error setting keymap: ' .. res, vim.log.levels.ERROR)
  end
end

---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts|string
function M.nmap(lhs, rhs, opts)
  M.map('n', lhs, rhs, opts)
end

---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts
function M.imap(lhs, rhs, opts)
  M.map('i', lhs, rhs, opts)
end

---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts
function M.tmap(lhs, rhs, opts)
  M.map('t', lhs, rhs, opts)
end

---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts
function M.vmap(lhs, rhs, opts)
  M.map('v', lhs, rhs, opts)
end

function M.ternary(cond, T, F, ...)
  if cond then
    return T(...)
  else
    return F(...)
  end
end

-- Implement a zero-indexed table
M.zeroIndexedTable = setmetatable({}, {
  __call = function(_, _t)
    return setmetatable({
      _internal = _t,
    }, {
      __index = function(self, k)
        return self._internal[k + 1]
      end,
      __newindex = function(self, k, v)
        self._internal[k + 1] = v
      end,
    })
  end,
})

-- Usage Example for the zero-indexed table
-- Basically debug code
function M.test()
  local table = { 1, 2, 3, 4 }
  local test = M.zeroIndexedTable(table)
  print(test[0])
  print(test[1])
  print(test[2])
  print(test[3])
end

---@param offset integer
function M.get_relative_line(offset)
  -- Get the current cursor row (1-indexed)
  local current_row = vim.api.nvim_win_get_cursor(0)[1]

  -- Calculate the target row (0-indexed for API functions)
  local target_row = current_row + offset

  -- Get the total number of lines in the buffer
  local line_count = vim.api.nvim_buf_line_count(0)

  -- Ensure the target row is within bounds
  if target_row < 0 or target_row > line_count then
    return nil, 'Target row is out of bounds'
  end

  -- Fetch and return the line
  local line = vim.api.nvim_buf_get_lines(0, target_row - 1, target_row, false)
  return line[1] or '', nil -- Return the line as a string
end

---@return string
function M.get_visual_selection()
  -- Get the marks for the selection
  local start_line, start_col = unpack(vim.api.nvim_buf_get_mark(0, '<'))
  local end_line, end_col = unpack(vim.api.nvim_buf_get_mark(0, '>'))

  -- Adjust end_col for visual mode differences
  -- In Neovim, end_col is inclusive, but we need to make it exclusive
  end_col = vim.fn.mode() == '\22' and vim.v.maxcol or end_col + 1

  -- Handle different visual modes
  local mode = vim.fn.visualmode()
  local lines = {}

  if mode == 'v' then -- Character-wise visual
    lines = vim.api.nvim_buf_get_text(0, start_line - 1, start_col, end_line - 1, end_col, {})
  elseif mode == 'V' then -- Line-wise visual
    lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  elseif mode == '\22' then -- Block-wise visual (^V)
    for i = start_line, end_line do
      local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
      if line then
        local col_end = math.min(#line, end_col)
        table.insert(lines, string.sub(line, start_col + 1, col_end))
      end
    end
  end

  return table.concat(lines, '\n')
end

---@return table
function M.custom_foldtext()
  local start = vim.fn.getline(vim.v.foldstart):gsub('\t', string.rep(' ', vim.o.tabstop))
  local end_str = vim.fn.getline(vim.v.foldend)
  local end_ = vim.trim(end_str)
  local result = {}

  ---@param items table
  ---@param s string
  ---@param lnum integer
  ---@param coloff? integer
  local function fold_virt_text(items, s, lnum, coloff)
    if not coloff then
      coloff = 0
    end
    local text = ''
    local hl
    for i = 1, #s do
      local char = s:sub(i, i)
      local hls = vim.treesitter.get_captures_at_pos(0, lnum, coloff + i - 1)
      local _hl = hls[#hls]
      if _hl then
        local new_hl = '@' .. _hl.capture
        if new_hl ~= hl then
          table.insert(items, { text, hl })
          text = ''
          hl = nil
        end
        text = text .. char
        hl = new_hl
      else
        text = text .. char
      end
    end
    table.insert(items, { text, hl })
  end

  fold_virt_text(result, start, vim.v.foldstart - 1)
  table.insert(result, { ' ... ', 'Delimiter' })
  fold_virt_text(result, end_, vim.v.foldend - 1, #(end_str:match '^(%s+)' or ''))
  return result
end

---@param workspace string
---@return string
function M.get_python_path(workspace)
  -- Check for activated virtualenv first
  if vim.env.VIRTUAL_ENV then
    vim.notify('Using env: ' .. vim.env.VIRTUAL_ENV, vim.log.levels.INFO, { title = 'LSP' })
    return vim.env.VIRTUAL_ENV .. '/bin/python'
  end

  if not workspace then
    -- Fallback to system Python
    vim.print 'Falling back to system Python'
    return vim.fn.exepath 'python3' or vim.fn.exepath 'python' or 'python'
  end

  -- Try .venv directory
  local venv_path = workspace .. '/.venv/bin/python'
  if vim.fn.executable(venv_path) == 1 then
    vim.notify('Using env: ' .. venv_path, vim.log.levels.INFO, { title = 'LSP' })
    return venv_path
  end

  -- Try venv directory
  local venv_alt_path = workspace .. '/venv/bin/python'
  if vim.fn.executable(venv_alt_path) == 1 then
    vim.notify('Using env: ' .. venv_alt_path, vim.log.levels.INFO, { title = 'LSP' })
    return venv_alt_path
  end

  -- if workspace has pyproject.toml but not .venv
  if vim.fn.filereadable(workspace .. '/pyproject.toml') == 1 then
    vim.notify 'No venv exists for project, create one with "uv" or "poetry"'
  end

  -- Fallback to system Python
  vim.print 'Falling back to system Python'
  return vim.fn.exepath 'python3' or vim.fn.exepath 'python' or 'python'
end

-- Pure Lua workspace file collection and workspace diagnostics trigger
---@param client vim.lsp.Client
---@return string[]|string files List of file paths in the workspace
function M.get_workspace_files(client)
  local workspace_dir = client.root_dir or vim.fn.getcwd()

  -- Synchronously collect files using ripgrep via systemlist
  -- Returns an array of file paths (newline-separated output split into lines)
  local ok, results = pcall(vim.fn.systemlist, {
    'rg',
    '--files',
    '--hidden',
    workspace_dir,
  })

  if not ok or vim.v.shell_error ~= 0 then
    vim.notify('Failed to collect workspace files with ripgrep: ' .. (results or 'unknown error'), vim.log.levels.WARN)
    return {}
  end

  return results or {}
end

---Debug function: Print all keymaps for a given mode
---@param mode string
function M.debug_keymaps(mode)
  local mappings = vim.api.nvim_get_keymap(mode)
  for i, map in pairs(mappings) do
    vim.print(string.format('[%d] lhs=%q rhs=%q', i, map.lhs, map.rhs or ''))
  end
end

return M
