local M = {}

M.get_terminal_buffers = function()
  return vim.tbl_filter(function(buf)
    return vim.bo[buf].buftype == 'terminal'
  end, vim.api.nvim_list_bufs())
end

M.get_terminal_windows = function()
  local current_tabpage = vim.api.nvim_get_current_tabpage()
  return vim.tbl_filter(function(win)
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.api.nvim_win_get_tabpage(win) == current_tabpage and vim.bo[buf].buftype == 'terminal'
  end, vim.api.nvim_list_wins())
end

M.create_terminal_buffer = function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('filetype', 'terminal', { buf = buf })
  return buf
end

M.create_terminal_window = function(buf)
  return vim.api.nvim_open_win(buf, true, {
    split = 'below',
    style = 'minimal',
  })
end

M.create_or_open_terminal = function()
  local windows = M.get_terminal_windows()
  local buffers = M.get_terminal_buffers()
  local buf = next(buffers) == nil and M.create_terminal_buffer() or buffers[1]
  local win = next(windows) == nil and M.create_terminal_window(buf) or windows[1]
  if next(buffers) == nil then
    vim.fn.termopen(vim.o.shell)
  end
  return win
end

M.toggle_terminal = function()
  if vim.list_contains(M.get_terminal_windows(), vim.api.nvim_get_current_win()) then
    vim.cmd.close()
  else
    M.create_or_open_terminal()
  end
end

M.defaults = {
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

M.toggleterm = function()
  if not vim.api.nvim_buf_is_valid(M.buf or -1) then
    M.buf = vim.api.nvim_create_buf(false, false)
  end

  M.win = vim.iter(vim.fn.win_findbuf(M.buf)):find(function(b_wid)
    return vim.iter(vim.api.nvim_tabpage_list_wins(0)):any(function(t_wid)
      return b_wid == t_wid
    end)
  end) or vim.api.nvim_open_win(M.buf, false, M.defaults.winopt)

  if vim.api.nvim_win_get_config(M.win).hide then
    vim.api.nvim_win_set_config(M.win, { hide = false })
    vim.api.nvim_set_current_win(M.win)
    if vim.bo[M.buf].channel <= 0 then
      vim.fn.termopen(M.defaults.cmd)
    end
    vim.cmd 'startinsert'
  else
    vim.api.nvim_win_set_config(M.win, { hide = true })
    vim.api.nvim_set_current_win(vim.fn.win_getid(vim.fn.winnr '#'))
  end
end


M.setup = function()
    vim.api.nvim_create_user_command("Terminal", M.toggleterm, { desc = "Toggle terminal" })
    vim.keymap.set({ "n", "t" }, "<leader>tt", M.toggleterm, { desc = "[T]oggle [T]erminal", silent = true })
end

return M
