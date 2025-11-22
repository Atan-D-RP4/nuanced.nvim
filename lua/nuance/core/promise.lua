local M = {}

--- A Promise-like object for asynchronous operations
---@class AsyncPromise
---@field after fun(self: AsyncPromise, cb: fun(result: any)): AsyncPromise
---@field catch fun(self: AsyncPromise, cb: fun(err: any)): AsyncPromise
---@field settle fun(self: AsyncPromise, cb: fun(success: boolean, value: any)): AsyncPromise
---@field await_sync fun(self: AsyncPromise, timeout_ms?: integer): (string, any)
---@field cancel fun(self: AsyncPromise): AsyncPromise
AsyncPromise = {}

--- @param ms integer Delay in milliseconds before executing the callback (must be >= 0)
--- @param fn function The function to execute asynchronously
--- @param ... any Arguments to pass to the function
--- @return AsyncPromise
function M.async_promise(ms, fn, ...)
  if type(ms) ~= 'number' or ms < 0 then
    ms = 0
  end
  if type(fn) ~= 'function' then
    error('async_promise: second argument must be a function', 2)
  end

  local args = { ... }

  local state = 'pending'
  local value = nil
  local timer = vim.uv.new_timer()
  local callbacks = {
    fulfilled = {},
    rejected = {},
    finally = {},
  }

  local function run_callbacks(list, ...)
    for _, cb in ipairs(list) do
      local va_args = ...
      vim.schedule(function()
        local ok, err = pcall(cb, va_args)
        if not ok then
          vim.notify(string.format('[async_promise] error in callback: %s', tostring(err)), vim.log.levels.WARN)
        end
      end)
    end
  end

  local function settle_fulfill(res)
    if state ~= 'pending' then
      return
    end
    state = 'fulfilled'
    value = res
    run_callbacks(callbacks.fulfilled, res)
    run_callbacks(callbacks.finally)
    -- cleanup
    callbacks = { fulfilled = {}, rejected = {}, finally = {} }
  end

  local function settle_reject(err)
    if state ~= 'pending' then
      return
    end
    state = 'rejected'
    value = err
    run_callbacks(callbacks.rejected, err)
    if #callbacks.rejected == 0 then
      vim.schedule(function()
        vim.notify(string.format('[async_promise] uncaught error: %s', tostring(err)), vim.log.levels.ERROR)
      end)
    end
    run_callbacks(callbacks.finally)
    callbacks = { fulfilled = {}, rejected = {}, finally = {} }
  end

  ---@type AsyncPromise
  local promise = {}

  function promise:after(cb)
    if type(cb) ~= 'function' then
      return self
    end
    if state == 'fulfilled' then
      vim.schedule(function()
        pcall(cb, value)
      end)
    elseif state == 'pending' then
      table.insert(callbacks.fulfilled, cb)
    end
    return self
  end

  function promise:catch(cb)
    if type(cb) ~= 'function' then
      return self
    end
    if state == 'rejected' then
      vim.schedule(function()
        pcall(cb, value)
      end)
    elseif state == 'pending' then
      table.insert(callbacks.rejected, cb)
    end
    return self
  end

  function promise:finally(cb)
    if type(cb) ~= 'function' then
      return self
    end
    if state ~= 'pending' then
      vim.schedule(function()
        pcall(cb)
      end)
    else
      table.insert(callbacks.finally, cb)
    end
    return self
  end

  function promise:cancel()
    if state == 'pending' then
      state = 'cancelled'
      value = nil
      if timer then
        timer:stop()
        timer:close()
        timer = nil
      end
      run_callbacks(callbacks.finally)
      callbacks = { fulfilled = {}, rejected = {}, finally = {} }
    end
    return self
  end

  function promise:is_pending()
    return state == 'pending'
  end
  function promise:is_fulfilled()
    return state == 'fulfilled'
  end
  function promise:is_rejected()
    return state == 'rejected'
  end
  function promise:is_cancelled()
    return state == 'cancelled'
  end
  function promise:state()
    return state
  end

  function promise:settle(cb)
    if type(cb) ~= 'function' then
      error('settle() requires callback', 2)
    end
    if state == 'fulfilled' then
      vim.schedule(function()
        cb(true, value)
      end)
    elseif state == 'rejected' then
      vim.schedule(function()
        cb(false, value)
      end)
    elseif state == 'cancelled' then
      vim.schedule(function()
        cb(false, 'Promise was cancelled')
      end)
    else
      self
        :after(function(res)
          cb(true, res)
        end)
        :catch(function(err)
          cb(false, err)
        end)
    end
    return self
  end

  -- inside your promise definition
  function promise:await_sync(timeout_ms)
    timeout_ms = timeout_ms or math.huge

    -- If already settled, return immediately
    if state ~= 'pending' then
      return state, value
    end

    -- Use vim.wait to block until state is not pending or timeout
    local ok, ret = vim.wait(timeout_ms, function()
      return state ~= 'pending'
    end, 50)

    if not ok then
      -- timed out
      return 'timeout', nil
    end

    -- settled
    return state, value
  end

   -- Start timer
   timer:start(
     ms,
     0,
     vim.schedule_wrap(function()
       if state ~= 'pending' then
         assert(timer, "Timer must exist in its own callback")
         timer:close()
         return
       end

       local ok, res = pcall(function()
         return fn(args)
       end)

       if ok then
         settle_fulfill(res)
       else
         settle_reject(res)
       end

       assert(timer, "Timer must exist in its own callback")
       if not timer:is_closing() then
         pcall(function()
           timer:close()
         end)
         timer = nil
       end
     end)
   )

  return promise
end

return M
