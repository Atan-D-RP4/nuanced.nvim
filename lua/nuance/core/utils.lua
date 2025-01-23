local M = {}

---@param modes string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
M.is_key_mapped = function(modes, lhs)
  -- Normalize modes to a list if it's a single string
  if type(modes) == 'string' then
    modes = { modes }
  end

  for _, mode in ipairs(modes) do
    local mappings = vim.api.nvim_get_keymap(mode)
    for _, map in pairs(mappings) do
      if map.lhs == lhs then
        return true
      end
    end
  end

  return false
end

--
---@param modes string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
M.unmap = function(modes, lhs)
  -- Normalize modes to a list if it's a single string
  if type(modes) == 'string' then
    modes = { modes }
  end

  -- Delete existing mappings for all specified modes
  for _, mode in ipairs(modes) do
    if M.is_key_mapped(mode, lhs) then
      vim.keymap.del(mode, lhs)
    end
  end
end

--- An abstraction over |nvim_set_keymap()| that unmaps the key before setting it.
---@param modes string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts|string
M.map = function(modes, lhs, rhs, opts)
  M.unmap(modes, lhs)
  -- Set new mapping
  local options = { noremap = true, silent = true }
  if opts then
    if type(opts) == 'string' then
      opts = { desc = opts }
    end
    options = vim.tbl_extend('force', options, opts)
  end
  vim.keymap.set(modes, lhs, rhs, options)
end

---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts|string
M.nmap = function(lhs, rhs, opts)
  M.map('n', lhs, rhs, opts)
end

---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts
M.imap = function(lhs, rhs, opts)
  M.map('i', lhs, rhs, opts)
end

---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts
M.tmap = function(lhs, rhs, opts)
  M.map('t', lhs, rhs, opts)
end

---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts
M.vmap = function(lhs, rhs, opts)
  M.map('v', lhs, rhs, opts)
end

M.ternary = function(cond, T, F, ...)
  if cond then
    return T(...)
  else
    return F(...)
  end
end

M.lazy_require = function(module)
  return function()
    require(module)
  end
end

-- Implement a zero-indexed table
M.zeroIndexedTable = setmetatable({}, {
  __call = function(self, _t)
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
M.test = function()
  local table = { 1, 2, 3, 4 }
  local test = M.zeroIndexedTable(table)
  vim.print(test[0])
  vim.print(test[1])
  vim.print(test[2])
  vim.print(test[3])
end

M.term_conf = {
  cmd = { vim.o.shell },
  winopt = {
    relative = 'editor',
    col = math.floor(vim.o.columns * 0.1),
    row = math.floor(vim.o.lines * 0.1),
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
    border = 'rounded',
    style = 'minimal',
    hide = true,
  },
}

M.term_send_cmd = function(cmd)
  -- Prompt for a command to send to the terminal
  if not cmd then
    cmd = vim.fn.input 'Command: '
  end
  cmd = cmd .. '\r\n'

  if M.term_conf.term_id == nil then
    vim.fn.jobstart(M.term_conf.cmd, { term = true })
    M.term_conf.term_id = vim.bo[M.buf].channel
  end

  -- Send the command
  if vim.bo[M.buf].channel > 0 then
    vim.fn.chansend(M.term_conf.term_id, cmd)
  end
end

---@param key string
M.term_send_key = function(key)
  if not key then
    return
  end

  if M.term_conf.term_id == nil then
    vim.fn.jobstart(M.term_conf.cmd, { term = true })
    M.term_conf.term_id = vim.bo[M.buf].channel
  end

  key = vim.api.nvim_replace_termcodes(key, true, true, true)
  if vim.bo[M.buf].channel > 0 then
    vim.fn.chansend(M.term_conf.term_id, key)
  end
end

---@param keys string[]|string
M.term_send_keys = function(keys)
  if not keys then
    return
  end

  if type(keys) == 'string' then
    keys = { keys }
  end

  for _, key in ipairs(keys) do
    M.term_send_key(key)
  end
end

M.toggleterm = function()
  if not vim.api.nvim_buf_is_valid(M.buf or -1) then
    M.buf = vim.api.nvim_create_buf(false, false)
  end

  M.win = vim.iter(vim.fn.win_findbuf(M.buf)):find(function(b_wid)
    return vim.iter(vim.api.nvim_tabpage_list_wins(0)):any(function(t_wid)
      return b_wid == t_wid
    end)
  end) or vim.api.nvim_open_win(M.buf, false, M.term_conf.winopt)

  if vim.api.nvim_win_get_config(M.win).hide then
    vim.api.nvim_win_set_config(M.win, { hide = false })
    vim.api.nvim_set_current_win(M.win)
    if vim.bo[M.buf].channel <= 0 then
      vim.fn.jobstart(M.term_conf.cmd, { term = true })

      M.term_conf.term_id = vim.bo[M.buf].channel
    end
    vim.cmd 'startinsert'
  else
    vim.api.nvim_win_set_config(M.win, { hide = true })
    vim.api.nvim_set_current_win(vim.fn.win_getid(vim.fn.winnr '#'))
  end
end

M.buftab_setup = function()
  -- NOTE: This does not work since any of the buffer delete operations don't seemd to trigger this autocommand
  vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete', 'BufEnter', 'BufUnload', 'BufHidden', 'BufNewFile', 'BufNew' }, {
    desc = 'Trigger an Autocommand everytime the buffer list changes',
    group = vim.api.nvim_create_augroup('nuance-buftabs', { clear = true }),
    pattern = '*',
    callback = function()
      vim.g.nuance_buftabs_count = vim.g.nuance_buftabs_count or 0
      vim.g.nuance_buftabs_count = vim.g.nuance_buftabs_count + 1
      vim.schedule(function()
        vim.g.tab_idx_map = nil
        local bufs = vim.api.nvim_exec2('buffers', { output = true }).output
        bufs = vim.split(bufs, '\n', { trimempty = true })
        bufs = vim.tbl_map(function(s)
          return tonumber(vim.split(s, ' ', { trimempty = true })[1])
        end, bufs)
        local tab_idx_map = {}
        local idx = 1
        for _, bufnr in ipairs(bufs) do
          tab_idx_map[bufnr] = idx
          idx = idx + 1
        end
        vim.g.tab_idx_map = tab_idx_map
      end)
    end,
  })
end

---@param offset integer
M.get_relative_line = function(offset)
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

return M
