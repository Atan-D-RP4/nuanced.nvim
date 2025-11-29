-- Lifted from: https://github.com/neo451/dot/blob/main/nvim/.config/nvim/plugin/lsp_dial.lua
-- Posted on: https://www.reddit.com/r/neovim/comments/1k95s17/dial_enum_members_with_ca_cx/
--- Scroll through enum/boolean values like a dial
---
--- This module provides <C-a>/<C-x> bindings that cycle through:
--- - Numbers (via Vim's built-in increment/decrement)
--- - Boolean values (true/false, yes/no, on/off, etc.)
--- - Enum-like values (extracted from code comments or type hints)
-- Example
---@type "a" | "b" | "c" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p"
local _enum = 'a'

local M = {}

--- Extract possible values from a type comment above the current line
--- Example: -- @type "option1" | "option2" | "option3"
---@return table -- List of enum items {label}
function M._extract_from_type_comment()
  local items = {}
  local linenr = vim.fn.line '.'

  -- Check lines above current line for type hints
  for i = linenr - 1, math.max(1, linenr - 10), -1 do
    local line = vim.fn.getline(i)

    -- Look for @type annotations with union types
    local type_match = line:match '@type%s+(.+)'
    if type_match then
      -- Parse union type: "a" | "b" | "c"
      for item in type_match:gmatch '"([^"]+)"' do
        table.insert(items, { label = item })
      end
      if not vim.tbl_isempty(items) then
        return items
      end
    end

    -- Look for inline union types: string | enum pattern
    local inline_match = line:match '(%w+)%s*=%s*["\']([^"\']+)["\']%s*%|'
    if inline_match then
      -- Extract all quoted values from the union
      for item in line:gmatch '"([^"]+)"' do
        table.insert(items, { label = item })
      end
      for item in line:gmatch "'([^']+)'" do
        table.insert(items, { label = item })
      end
      if not vim.tbl_isempty(items) then
        return items
      end
    end
  end

  return items
end

--- Try to get enum members using treesitter-based context analysis
---@param _word string -- The current word
---@return table -- List of enum items {label}
function M._get_context_enum_items(_word)
  local items = {}

  -- Try to extract from type comments first
  items = M._extract_from_type_comment()
  if not vim.tbl_isempty(items) then
    vim.notify('Found enum from type comment: ' .. table.concat(
      vim.tbl_map(function(i)
        return i.label
      end, items),
      ', '
    ), vim.log.levels.DEBUG)
    return items
  end

  -- TODO: Could add treesitter-based enum detection here
  -- This would require parsing the AST to find enum declarations

  return items
end

--- Function to scroll through enum values like a dial
---@param inc boolean -- true to increment, false to decrement
function M.lsp_dial(inc)
  -- If we're on a number, use Vim's built-in behavior
  if tonumber(vim.fn.expand '<cword>') ~= nil then
    local key = inc and '<C-a>' or '<C-x>'
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), 'n', false)
    return
  end

  -- Get cursor position and current word
  local word = vim.fn.expand '<cword>'
  if word == '' then
    -- Word is empty, fall back to default behavior
    local key = inc and '<C-a>' or '<C-x>'
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), 'n', false)
    return
  end

  -- Try built-in cycles first (fastest, doesn't require parsing)
  local builtin_cycles = {
    ['true'] = 'false',
    ['false'] = 'true',
    ['True'] = 'False',
    ['False'] = 'True',
    ['TRUE'] = 'FALSE',
    ['FALSE'] = 'TRUE',
    ['yes'] = 'no',
    ['no'] = 'yes',
    ['Yes'] = 'No',
    ['No'] = 'Yes',
    ['YES'] = 'NO',
    ['NO'] = 'YES',
    ['on'] = 'off',
    ['off'] = 'on',
    ['On'] = 'Off',
    ['Off'] = 'On',
    ['ON'] = 'OFF',
    ['OFF'] = 'ON',
  }

  local next_val = builtin_cycles[word]
  if next_val then
    M._replace_word(word, next_val)
    return
  end

  -- Try to get enum items from context (type comments, etc.)
  local items = M._get_context_enum_items(word)

  if vim.tbl_isempty(items) then
    vim.notify('No enum items found from type hints', vim.log.levels.WARN)
    -- Fall back to default behavior
    local key = inc and '<C-a>' or '<C-x>'
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), 'n', false)
    return
  end

  -- Find current item in the list
  local index
  local cleaned_word = word:gsub('^[\'"]', ''):gsub('[\'"]$', '')

  for i, item in ipairs(items) do
    -- Try several matching approaches
    if item.label == cleaned_word or item.label == word then
      index = i
      break
    end
  end

  if not index then
    vim.notify('Current value "' .. word .. '" not found in enum list', vim.log.levels.WARN)
    -- Fall back to default behavior
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
  assert(next_item ~= nil, 'Next enum item should exist')
  assert(next_item.label ~= nil, 'Next enum item should have a label')

  -- Replace the word with the next item
  M._replace_word(word, next_item.label)
end

--- Character class for word characters (includes underscore and handles most languages)
local function is_word_char(char)
  if not char or char == '' then
    return false
  end
  -- Match [a-zA-Z0-9_] which covers most programming languages
  return char:match '[%w_]' ~= nil
end

--- Replace current word with new text using direct buffer manipulation
---@param old_word string -- The word to replace
---@param new_word string -- The replacement word
function M._replace_word(old_word, new_word)
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Convert to 0-based indexing

  -- Get the current line
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]

  if not line then
    vim.notify('Failed to get current line', vim.log.levels.ERROR)
    return
  end

  -- Find the word boundaries around the cursor position
  -- col is 0-based in Neovim's cursor position (before the character)
  -- We need to work with 1-based Lua string indexing
  local char_pos = col + 1 -- Convert to 1-based position of character at cursor

  -- If we're past the end of the line, fallback
  if char_pos > #line then
    vim.notify('Cursor position past end of line', vim.log.levels.WARN)
    return
  end

  -- Find start of word by moving backward
  local word_start = char_pos
  while word_start > 1 and is_word_char(line:sub(word_start - 1, word_start - 1)) do
    word_start = word_start - 1
  end

  -- Find end of word by moving forward
  local word_end = char_pos
  while word_end < #line and is_word_char(line:sub(word_end + 1, word_end + 1)) do
    word_end = word_end + 1
  end

  -- Extract the word at cursor (1-based indexing for Lua string operations)
  local cursor_word = line:sub(word_start, word_end)

  -- Verify we're replacing the correct word
  if cursor_word ~= old_word then
    vim.notify('Cursor word "' .. cursor_word .. '" does not match expected "' .. old_word .. '"', vim.log.levels.WARN)
    return
  end

  -- Replace the word in the line (keeping 1-based indexing)
  local new_line = line:sub(1, word_start - 1) .. new_word .. line:sub(word_end + 1)

  -- Update the buffer
  vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { new_line })

  -- Keep cursor at the same position within the word
  local offset_in_word = col + 1 - word_start -- Offset from start of word
  local new_col_1based = word_start + math.min(offset_in_word, #new_word - 1)
  local new_col_0based = new_col_1based - 1 -- Convert back to 0-based for Neovim
  vim.api.nvim_win_set_cursor(0, { row + 1, new_col_0based })
end

M.setup = function()
  local map = require('nuance.core.utils').map
  vim.tbl_map(function(keymap)
    map(keymap[1], keymap[2], keymap[3] or '', keymap[4] or {})
  end, {
    {
      'n',
      '<C-a>',
      function()
        require('nuance.core.lsp_dial').lsp_dial(true)
      end,
      { noremap = true, desc = 'LSP Dial Increment' },
    },

    {
      'n',
      '<C-x>',
      function()
        require('nuance.core.lsp_dial').lsp_dial(false)
      end,
      { noremap = true, desc = 'LSP Dial Decrement' },
    },
  })
end

return M
