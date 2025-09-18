-- *buftabline.lua* Theovim Buftabline
-- $ figlet -f tinker-joy theovim
--  o  o
--  |  |                  o
-- -o- O--o o-o o-o o   o   o-O-o
--  |  |  | |-' | |  \ /  | | | |
--  o  o  o o-o o-o   o   | o o o
--
-- Initialize buftabline with:
-- - Clickable buffer list
-- - Buffer index from nuance_buftabs_count
-- - Highlights for active/inactive buffers

Buftabline = {}

local logo = vim.g.have_nerd_font and "  " or "Nuance"

---Get a list of all listed buffers
---@return table List of buffer numbers
local function getListedBuffers()
  local buffers = {}
  for b = 1, vim.fn.bufnr('$') do
    if vim.fn.buflisted(b) == 1 then
      table.insert(buffers, b)
    end
  end
  return buffers
end

---Get the buffer index from the global index map
---@param bufnr number Buffer number
---@return string Index string
local function getBufferIndex(bufnr)
  local idx_map = vim.g.tab_idx_map or {}
  return idx_map[bufnr] and tostring(idx_map[bufnr]) or ""
end

---Format a string for Vim buftabline
---@return string s Formatted string to be used as a Vim tabline
Buftabline.build = function()
  local s = "%#TabLineFill#" .. logo

  -- ========== Left ==========
  -- List of buffers
  -- ==========================

  local currBufNr = vim.fn.bufnr()
  local buffers = getListedBuffers()

  for _, bufnr in pairs(buffers) do
    -- Skip invalid buffers
    if not vim.api.nvim_buf_is_valid(bufnr) then goto continue end

    local bufIndex = getBufferIndex(bufnr)
    local isActive = bufnr == currBufNr

    -- Basic setup
    s = s .. (isActive and "%#TabLineSel#" or "%#TabLine#") --> diff hl for active and inactive buffers
    s = s .. " "                                            --> Left margin/separator

    -- Make buffer clickable
    s = s .. "%" .. bufnr .. "@BufferGo@"

    -- Buffer index
    if bufIndex ~= "" then
      s = s .. bufIndex .. ":"
    end

    local icon = require('mini.icons').get('file', 'file.' .. vim.bo[bufnr].filetype)
    s = s .. icon .. ' '

    -- Buffer name
    local bufname = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ":t")

    -- Give a name to an empty buffer
    if bufname == "" then
      bufname = "[No Name]"
    end

    -- Limit bufname to n character + 3 (accounting for "..." to be appended)
    local bufnameLimits = 18
    if string.len(bufname) > bufnameLimits + 3 then
      bufname = string.sub(bufname, 1, bufnameLimits) .. "..."
    end

    -- Add a flag to a modified buffer
    if vim.fn.getbufvar(bufnr, "&modified") == 1 then
      bufname = bufname .. "[+]"
    end

    -- Append formatted bufname
    s = s .. bufname

    -- Add close button
    s = s .. " %" .. bufnr .. "@BufferClose@"
    s = s .. (vim.g.have_nerd_font and "" or "X")
    s = s .. "%X"

    s = s .. " "
    s = s .. "%#TabLineFill# "

    ::continue::
  end

  -- ========== Middle ==========
  -- Empty space
  -- ============================
  s = s .. "%=" --> spacer

  -- ========== Right ==========
  -- Total buffer count
  -- ===========================
  s = s .. "%#TabLineSel#"
  s = s .. " " .. #buffers .. " buffer" .. (#buffers > 1 and "s" or "") .. " "

  -- Add a truncation starting point: truncate buffer information first
  s = s .. "%<"
  return s
end

-- Define buffer commands
local function defineBufferCommands()
  -- Command to go to buffer
  vim.cmd([[
    function! BufferGo(minwid, clicks, button, modifiers)
      execute "buffer " . a:minwid
    endfunction

    function! BufferClose(minwid, clicks, button, modifiers)
      execute "bdelete " . a:minwid
    endfunction
  ]])
end

-- Set buftabline. The Lua function called must be globally accessible
Buftabline.setup = function()
  defineBufferCommands()
  vim.go.tabline = "%!v:lua.Buftabline.build()"

  -- Run the buffer tab setup
  require('nuance.core.utils').buftab_setup()
end

return Buftabline
