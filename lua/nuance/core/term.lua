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

function M.term_send_cmd(cmd)
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
function M.term_send_keys(keys)
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

function M.toggleterm()
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

return M
