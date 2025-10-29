-- Lifted from: https://github.com/neo451/dot/blob/main/nvim/.config/nvim/plugin/lsp_dial.lua
-- Posted on: https://www.reddit.com/r/neovim/comments/1k95s17/dial_enum_members_with_ca_cx/
--- Scroll through LSP enum members like a dial

-- Example
---@type "a" | "b" | "c" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p"
local enum = 'f'

--- Function to scroll through LSP enum members like a dial
---@param inc boolean -- true to increment, false to decrement
function M.lsp_dial(inc)
  -- If we're on a number, use Vim's built-in behavior
  if tonumber(vim.fn.expand '<cword>') ~= nil then
    local key = inc and '<C-a>' or '<C-x>'
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), 'n', false)
    return
  end

  -- Get cursor position and current word
  local word = vim.fn.expand '<cword>' -- Using <cword> instead of <cWORD> for more precise matching
  local full_word = vim.fn.expand '<cWORD>' -- Backup for substitution if needed

  -- Get LSP completion at current position
  local params = vim.lsp.util.make_position_params(0, 'utf-8')
  local results = vim.lsp.buf_request_sync(0, vim.lsp.protocol.Methods.textDocument_completion, params)

  -- Process LSP completion items
  local items = {}
  if results and not vim.tbl_isempty(results) then
    for _, obj in ipairs(results) do
      local result = obj.result
      if result then
        -- Extract enum members
        for _, item in ipairs(result.items or {}) do
          if item.kind == vim.lsp.protocol.CompletionItemKind.EnumMember then
            -- Clean up the label (strip quotes, if any)
            local clean_label = item.label:gsub('^[\'"]', ''):gsub('[\'"]$', '')
            table.insert(items, {
              raw_label = item.label,
              label = clean_label,
              detail = item.detail,
            })
          end
        end
      end

      if not vim.tbl_isempty(items) then
        break
      end
    end
  end

  if vim.tbl_isempty(items) then
    vim.notify('No enum items found', vim.log.levels.WARN)
    -- Fall back to default behavior
    local key = inc and '<C-a>' or '<C-x>'
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), 'n', false)
    return
  end

  -- Find current item in the list
  local index
  local cleaned_word = word:gsub('^[\'"]', ''):gsub('[\'"]$', '') -- Strip quotes for comparison

  for i, item in ipairs(items) do
    -- Try several matching approaches
    if item.label == cleaned_word or item.raw_label == word or item.label == word then
      index = i
      break
    end
  end

  if not index then
    vim.notify('Current value not found in enum list', vim.log.levels.WARN)
    -- Not an enum value, use default behavior
    local key = inc and '<C-a>' or '<C-x>'
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), 'n', false)
    return
  end

  -- Calculate next index with wrapping
  if inc then
    index = index + 1
    if index > #items then
      index = 1
    end
  else
    index = index - 1
    if index < 1 then
      index = #items
    end
  end

  local next_item = items[index]

  -- Save cursor position
  local pos = vim.api.nvim_win_get_cursor(0)

  -- Try different substitution approaches
  local ok, err = pcall(function()
    -- Try substituting the exact word first
    vim.cmd('s/\\<' .. vim.fn.escape(word, '/\\') .. '\\>/' .. vim.fn.escape(next_item.label, '/\\'))
  end)

  if not ok then
    -- If that fails, try with the full CWORD
    ok, err = pcall(function()
      vim.cmd('s/' .. vim.fn.escape(full_word, '/\\') .. '/' .. vim.fn.escape(next_item.label, '/\\'))
    end)
  end

  if ok then
    vim.api.nvim_win_set_cursor(0, pos)
  else
    vim.notify('LSP dial error: ' .. tostring(err), vim.log.levels.ERROR)
    -- Fall back to default behavior on error
    local key = inc and '<C-a>' or '<C-x>'
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), 'n', false)
  end
end

-- Simple direct mappings that don't use expressions
-- vim.keymap.set('n', '<C-a>', function()
--   M.lsp_dial(true)
-- end, { noremap = true })
-- vim.keymap.set('n', '<C-x>', function()
--   M.lsp_dial(false)
-- end, { noremap = true })

return M
