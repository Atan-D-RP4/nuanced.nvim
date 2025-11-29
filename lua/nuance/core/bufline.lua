-- Inspired by: https://www.reddit.com/r/neovim/comments/1kkuu5h/wow_i_just_wrote_my_own_tabline_in_lua_with/
-- Nuance Buftabline

-- Clickable buffer list
-- Buffer index from vim.g.tab_idx_map
-- Highlights for active/inactive buffers

---@class Bufline
Bufline = {
  buftabs_count = 1, -- Number of buffers in the tabline
  tab_idx_map = {}, -- Map of buffer numbers to their index in the tabline
  curr_buf_idx = 0, -- Current buffer index
  logo = vim.g.have_nerd_font and '  ' or ' [B] ',
}

---Update keymap descriptions with current buffer names
local function update_keymap_descriptions()
  local nmap = require('nuance.core.utils').nmap

  for index = 1, Bufline.buftabs_count do
    local desc = string.format('Jump to buffer %d', index)

    -- Find the buffer at this index
    local buffers = {}
    for b = 1, vim.fn.bufnr '$' do
      if vim.fn.buflisted(b) == 1 then
        table.insert(buffers, b)
      end
    end

    if index <= #buffers then
      local bufnr = buffers[index]
      local bufname = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t')
      if bufname == '' then
        bufname = '[No Name]'
      end
      desc = string.format('Jump to buffer %d: %s', index, bufname)
    end

    nmap(string.format('<leader>e%d', index), function()
      Bufline.buf_switch(index)
    end, desc)
  end
end

function Bufline.buftab_setup()
  vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete', 'BufEnter', 'BufUnload', 'BufHidden', 'BufNewFile', 'BufNew' }, {
    desc = 'Trigger an Autocommand everytime the buffer list changes',
    group = require('nuance.core.utils').augroup 'buftabs-setup',
    callback = function()
      local bufs = vim.api.nvim_exec2('exec "buffers"', { output = true }).output
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
      Bufline.tab_idx_map = tab_idx_map

      -- Store current buffer index
      local current_bufnr = vim.fn.bufnr()
      Bufline.curr_buf_idx = tab_idx_map[current_bufnr] or 0

      -- Update keymap descriptions with current buffer names
      update_keymap_descriptions()
    end,
  })

  -- Initial keymap setup
  update_keymap_descriptions()
end

---Get a list of all listed buffers
---@return table List of buffer numbers
local function getListedBuffers()
  local buffers = {}
  for b = 1, vim.fn.bufnr '$' do
    if vim.fn.buflisted(b) == 1 then
      table.insert(buffers, b)
    end
  end
  return buffers
end

---Get the buffer index from the global index map
---@param bufnr number Buffer number
---@return string Index string
function Bufline.getBufferIndex(bufnr)
  local idx_map = Bufline.tab_idx_map
  return idx_map[bufnr] and tostring(idx_map[bufnr]) or ''
end

---Format a string for Vim buftabline
---@return string s Formatted string to be used as a Vim tabline
Bufline.build = function()
  local s = '%#TabLineFill#' .. Bufline.logo

  -- ========== Left ==========
  -- List of buffers
  -- ==========================

  local currBufNr = vim.fn.bufnr()
  local buffers = getListedBuffers()
  Bufline.buftabs_count = #buffers

  for _, bufnr in pairs(buffers) do
    -- Skip invalid buffers
    if not vim.api.nvim_buf_is_valid(bufnr) then
      goto continue
    end

    local bufIndex = Bufline.getBufferIndex(bufnr)
    local isActive = bufnr == currBufNr

    -- Basic setup
    s = s .. (isActive and '%#TabLineSel#' or '%#TabLine#') --> diff hl for active and inactive buffers
    s = s .. ' ' --> Left margin/separator

    -- Make buffer clickable
    s = s .. '%' .. bufnr .. '@BufferGo@'

    -- Buffer index
    if bufIndex ~= '' then
      s = s .. bufIndex .. ':'
    end

    local icon = MiniIcons ~= nil and MiniIcons.get('file', 'file.' .. vim.bo[bufnr].filetype) or '' -- Default icon if Mini Icons is not available
    s = s .. icon .. ' '

    -- Buffer name
    local bufname = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t')

    -- Give a name to an empty buffer
    if bufname == '' then
      bufname = '[No Name]'
    end

    -- Limit bufname to n character + 3 (accounting for "..." to be appended)
    local bufnameLimits = 18
    if string.len(bufname) > bufnameLimits + 3 then
      bufname = string.sub(bufname, 1, bufnameLimits) .. '...'
    end

    -- Add a flag to a modified buffer
    if vim.fn.getbufvar(bufnr, '&modified') == 1 then
      bufname = bufname .. '[+]'
    end

    -- Append formatted bufname
    s = s .. bufname

    -- Add close button
    s = s .. ' %' .. bufnr .. '@BufferClose@'
    s = s .. (vim.g.have_nerd_font and '' or 'X')
    s = s .. '%X'

    s = s .. ' '
    s = s .. '%#TabLineFill# '
    ::continue::
  end

  -- ========== Middle ==========
  -- Empty space
  -- ============================
  s = s .. '%=' --> spacer

  -- ========== Right ==========
  -- Total buffer count
  -- ===========================
  s = s .. '%#TabLineSel#'
  s = s .. ' ' .. #buffers .. ' buffer' .. (#buffers > 1 and 's' or '') .. ' '

  -- Add a truncation starting point: truncate buffer information first
  s = s .. '%<'
  return s
end

-- Define buffer commands
local function defineBufferCommands()
  -- Command to go to buffer
  vim.cmd [[
    function! BufferGo(minwid, clicks, button, modifiers)
      execute "buffer " . a:minwid
    endfunction

    function! BufferClose(minwid, clicks, button, modifiers)
      execute "bdelete " . a:minwid
    endfunction
  ]]
end

Bufline.buf_switch = function(index)
  local ok_list, bufs = pcall(vim.api.nvim_list_bufs)
  if not ok_list then
    vim.notify('Failed to list buffers', vim.log.levels.ERROR)
    return
  end

  local valid_bufs = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
  end, bufs)

  if index > #valid_bufs then
    vim.notify('Buffer index out of range', vim.log.levels.WARN)
    return
  end

  local target_buf = valid_bufs[index]
  if not target_buf then
    vim.notify('No buffer found at index ' .. index, vim.log.levels.ERROR)
    return
  end
  local ok_set, err = pcall(vim.api.nvim_set_current_buf, target_buf)
  if not ok_set then
    vim.notify('Failed to switch buffer: ' .. err, vim.log.levels.ERROR)
  end
end

-- Set buftabline. The Lua function called must be globally accessible
Bufline.setup = function()
  -- Show Tabline
  vim.opt.showtabline = 2

  defineBufferCommands()

  -- Run the buffer tab setup
  Bufline.buftab_setup()
  vim.go.tabline = '%!v:lua.Bufline.build()'
end

return Bufline
