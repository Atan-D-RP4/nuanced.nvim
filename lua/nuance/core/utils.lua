local M = {}

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

M.nmap = function(lhs, rhs, opts)
  M.map('n', lhs, rhs, opts)
end

M.imap = function(lhs, rhs, opts)
  M.map('i', lhs, rhs, opts)
end

M.tmap = function(lhs, rhs, opts)
  M.map('t', lhs, rhs, opts)
end

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

M.term_send = function(cmd)
  -- Prompt for a command to send to the terminal
  if not cmd then
    cmd = vim.fn.input 'Command: '
    cmd = cmd .. '\r'
  end

  -- Send the command
  if vim.bo[M.buf].channel > 0 then
    vim.fn.chansend(M.term_conf.term_id, cmd)
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
      vim.fn.termopen(M.term_conf.cmd)
      M.term_conf.term_id = vim.bo[M.buf].channel
    end
    vim.cmd 'startinsert'
  else
    vim.api.nvim_win_set_config(M.win, { hide = true })
    vim.api.nvim_set_current_win(vim.fn.win_getid(vim.fn.winnr '#'))
  end
end


M.netrw_setup = function()
  vim.g.netrw_banner = 0
  vim.g.netrw_fastbrowse = 1
  vim.g.netrw_keepdir = 1
  vim.g.netrw_silent = 1
  vim.g.netrw_special_syntax = 1
  vim.g.netrw_bufsettings = 'noma nomod nonu nowrap ro nobl relativenumber'
  vim.g.netrw_liststyle = 3
  vim.g.netrw_browse_split = 4
  vim.cmd [[
    let g:netrw_list_hide = netrw_gitignore#Hide()
    let g:netrw_list_hide.=',\(^\|\s\s\)\zs\.\S\+'
  ]]
  -- vim.g.EasyMotion_startofline = 0
  -- vim.g.EasyMotion_smartcase = 1
end

return M
