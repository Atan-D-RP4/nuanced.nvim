local M = {}

--@param bufnr integer
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
function M.is_key_mapped(modes, lhs)
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

---@param modes string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
function M.unmap(modes, lhs)
  -- Normalize modes to a list if it's a single string
  if type(modes) == 'string' then
    modes = { modes }
  end

  -- Delete existing mappings for all specified modes
  for _, mode in ipairs(modes) do
    local key_is_mapped = M.is_key_mapped(mode, lhs)
    if key_is_mapped then
      pcall(vim.keymap.del, mode, lhs, { buffer = vim.api.nvim_get_current_buf() })
    end
  end
end

--- An abstraction over |nvim_set_keymap()| that unmaps the key before setting it.
---@param modes string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts|string
function M.map(modes, lhs, rhs, opts)
  M.unmap(modes, lhs)
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

---@param timeout integer Delay in milliseconds before executing the callback
---@param repeat_ integer Unused - kept for backwards compatibility
---@param callback function The async function to execute
---@param arg1? any First argument passed to callback
---@param ... any Additional arguments passed to callback
---@return table Promise-like object with after/catch/await methods
function M.async_promise(timeout, repeat_, callback, arg1, ...)
  -- Parameter validation
  if type(timeout) ~= 'number' or timeout < 0 then
    timeout = 100 -- Default timeout
  end
  if type(callback) ~= 'function' then
    error 'async_promise: callback must be a function'
  end

  -- Use vim.loop (libuv) for async operations
  local timer = vim.uv.new_timer()
  if timer == nil then
    local err_promise = {
      pending = false,
      result = nil,
      error = 'Failed to create timer',
      after = function(self)
        return self
      end,
      catch = function(self, fn)
        fn(self.error)
        return self
      end,
      await = function()
        error 'Failed to create timer'
      end,
    }
    vim.notify('Failed to create timer', vim.log.levels.ERROR)
    return err_promise
  end

  local args = { ... }

  -- Create a promise-like interface
  local promise = {
    pending = true,
    result = nil,
    error = nil,
  }

  -- Store callbacks
  local after_callbacks = {}
  local catch_callbacks = {}

  -- Add default error handler
  table.insert(catch_callbacks, function(err)
    vim.notify(string.format('Async operation failed: %s', tostring(err)), vim.log.levels.ERROR)
  end)

  -- Add then method
  function promise.after(fn)
    if promise.pending then
      table.insert(after_callbacks, fn)
    elseif not promise.error then
      fn(promise.result)
    end
    return promise
  end

  -- Add catch method
  function promise.catch(fn)
    if promise.pending then
      table.insert(catch_callbacks, fn)
    elseif promise.error then
      fn(promise.error)
    end
    return promise
  end

  -- Add await method
  function promise.await()
    if promise.pending then
      vim.wait(timeout * 2, function() -- Double timeout to ensure completion
        return not promise.pending
      end)
    end
    if promise.error then
      error(promise.error)
    end
    return promise.result
  end

  -- Execute async operation
  timer:start(
    timeout,
    repeat_,
    vim.schedule_wrap(function()
      -- Call the callback function with the provided arguments and capture result
      local success, result = pcall(callback, arg1, unpack(args))

      -- Update promise status
      promise.pending = false

      if success then
        promise.result = result
        -- Execute after callbacks
        for _, fn in ipairs(after_callbacks) do
          local ok, err = pcall(fn, result)
          if not ok then
            vim.notify(string.format('Error in after callback: %s', err), vim.log.levels.WARN)
          end
        end
      else
        promise.error = result
        -- Execute catch callbacks
        for _, fn in ipairs(catch_callbacks) do
          local ok, err = pcall(fn, result)
          if not ok then
            vim.notify(string.format('Error in catch callback: %s', err), vim.log.levels.WARN)
          end
        end
      end

      timer:close()
    end)
  )

  return promise
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
function M.get_workspace_files(client)
  local cwd = client.root_dir or vim.fn.getcwd()
  local results = {}

  -- Use ripgrep to collect files
  local function scan_files_with_ripgrep(path)
    local handle = io.popen('rg --files --hidden ' .. path)
    if handle then
      for line in handle:lines() do
        table.insert(results, line)
      end
      handle:close()
    end
  end

  scan_files_with_ripgrep(cwd)
  return results
end

-- Test function with multiple cases to demonstrate the async_do2 functionality
-- (function()
--   vim.print '\n--- Testing async_do function ---'
--
--   -- Test Case 1: Successful operation with simple return value
--   vim.print '\nTest Case 1: Successful operation'
--   local result
--   M.async_do(100, 0, function(result)
--     vim.print 'Running success case...'
--     result = 'Success result'
--     return 'Success result'
--   end, result)
--     .after(function(result)
--       vim.print('Success callback received:', result)
--       result = 'Manually set result'
--       return 'Chained result' -- Test that we can chain results
--     end)
--     .after(function(result)
--       vim.print('Chained callback received:', result or 'nil')
--     end)
--     .catch(function(err)
--       vim.print('This should not run for success case:', err)
--     end)
--
--   -- Test Case 2: Error handling
--   vim.print '\nTest Case 2: Error handling'
--   M.async_do(200, 0, function()
--     vim.print 'Running error case...'
--     error 'Deliberate error'
--     return "This won't return"
--   end)
--     .after(function(result)
--       vim.print('This should not run for error case:', result)
--     end)
--     .catch(function(err)
--       vim.print('Error caught:', err)
--       return 'Recovered from error'
--     end)
--     .after(function(result)
--       vim.print('After error handling:', result or 'nil')
--     end)
--
--   -- Test Case 3: Multiple return values
--   vim.print '\nTest Case 3: Multiple return values'
--   M.async_do(300, 0, function()
--     vim.print 'Running multiple returns case...'
--     return true, { data = 'some data' }, 'extra info'
--   end).after(function(ok, data, extra)
--     vim.print('Multiple returns - first value:', ok)
--     vim.print 'Multiple returns - other values may be nil due to Lua limitations'
--     return ok
--   end)
--
--   -- Test Case 4: Testing with arguments
--   vim.print '\nTest Case 4: Passing arguments'
--   local test_arg = 'test argument'
--   M.async_do(400, 0, function(arg)
--     vim.print('Received argument:', arg)
--     return 'Processed ' .. arg
--   end, test_arg).after(function(result)
--     vim.print('Result with argument:', result)
--   end)
--
--   -- Test Case 5: Timing test
--   vim.print '\nTest Case 5: Timing test (500ms delay)'
--   local start_time = os.time()
--   M.async_do(500, 0, function()
--     local elapsed = os.time() - start_time
--     vim.print('Timer callback executed after approximately', elapsed, 'seconds')
--     return elapsed
--   end).after(function(elapsed)
--     vim.print('Timing test completed:', elapsed)
--   end)
--
--   vim.print '\nAll tests queued. Results will appear asynchronously...\n'
-- end)()

return M
