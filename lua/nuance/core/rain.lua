---@meta
-------------------------------------------------------------------------------
--- Rain Animation Module for Neovim
-------------------------------------------------------------------------------
--- A cosmetic rain particle effect for Neovim's startup screen using extmarks
--- and libuv timers. Demonstrates async programming patterns in Neovim.
---
--- USAGE:
---   require('nuance.core.rain').setup({
---     drop_count = 5,           -- drops per spawn cycle
---     spawn_interval = 500,     -- ms between spawn cycles
---     drop_interval = 40,       -- ms between drop movements (speed)
---     diagonal_chance = 1,      -- probability of diagonal movement (0-1)
---     max_concurrent_drops = 200, -- memory safety limit
---   })
---
--- COMMANDS:
---   :Rain                       -- Toggle rain animation on/off
---
--- API:
---   M.rain()                    -- Start the rain animation
---   M.stop()                    -- Stop and clean up all resources
---   M.toggle()                  -- Toggle rain on/off
---   M.is_running()              -- Check if animation is active
---   M.setup(config)             -- Initialize with optional config overrides
---
-------------------------------------------------------------------------------
--- NEOVIM ASYNC PATTERNS DEMONSTRATED
-------------------------------------------------------------------------------
---
--- 1. VIM.UV TIMERS (libuv bindings)
---    Neovim exposes libuv's event loop via `vim.uv` (formerly `vim.loop`).
---    Timers allow non-blocking delayed/repeated execution.
---
---    Creating a timer:
---      local timer = vim.uv.new_timer()
---      assert(timer, "Failed to create timer")  -- Always check!
---
---    Starting a timer:
---      timer:start(delay_ms, repeat_ms, callback)
---      -- delay_ms:  Initial delay before first callback
---      -- repeat_ms: Interval for repeating (0 = one-shot)
---      -- callback:  Function to execute (MUST be wrapped, see below)
---
---    CRITICAL: vim.schedule_wrap()
---      Timer callbacks run in libuv's thread, NOT Neovim's main loop.
---      ALL Neovim API calls MUST be wrapped:
---
---      timer:start(100, 50, vim.schedule_wrap(function()
---        -- Safe to call vim.api.* here
---        vim.api.nvim_buf_set_lines(...)
---      end))
---
---    Cleanup pattern (MUST do to avoid memory leaks):
---      if timer and not timer:is_closing() then
---        timer:stop()   -- Stop the timer
---        timer:close()  -- Release the handle
---      end
---
--- 2. VIM.DEFER_FN (simple delayed execution)
---    For one-shot delays without manual cleanup:
---      vim.defer_fn(function()
---        -- Runs after delay, already in main loop
---      end, delay_ms)
---
--- 3. EXTMARKS (virtual text overlays)
---    Extmarks are buffer annotations that move with text changes.
---
---    Create namespace (once per module):
---      local ns = vim.api.nvim_create_namespace("my-namespace")
---
---    Set extmark with virtual text:
---      local id = vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
---        virt_text = { { "text", "HighlightGroup" } },
---        virt_text_pos = "overlay",  -- overlay | eol | right_align
---        id = existing_id,           -- Update existing extmark
---      })
---
---    Delete extmark:
---      vim.api.nvim_buf_del_extmark(buf, ns, id)
---
---    Clear all in namespace:
---      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
---
--- 4. FLOATING WINDOWS
---    Create overlay windows for visual effects:
---      local win = vim.api.nvim_open_win(buf, false, {
---        relative = "editor",  -- editor | win | cursor
---        style = "minimal",    -- No line numbers, statusline, etc.
---        border = "none",
---        width = cols, height = rows,
---        row = 0, col = 0,
---        focusable = false,    -- Prevent accidental focus
---        zindex = 1,           -- Layer order (1 = bottom)
---      })
---      vim.wo[win].winblend = 100  -- Transparency (0-100)
---
-------------------------------------------------------------------------------
local M = {}

---@class RainConfig
---@field namespace_name string Namespace for extmarks
---@field chars string[] Characters for vertical rain drops
---@field diagonal_chars string[] Characters for diagonal rain drops
---@field drop_count integer Number of drops to spawn per interval
---@field spawn_interval integer Milliseconds between spawn batches
---@field drop_interval integer Milliseconds between drop movements (lower = faster)
---@field initial_delay integer Milliseconds before first spawn after start
---@field winblend integer Window transparency (0=opaque, 100=invisible)
---@field speed_variance integer Random variance added to drop_interval (+/-)
---@field diagonal_chance number Probability of diagonal movement (0.0-1.0)
---@field max_concurrent_drops integer Maximum drops before evicting oldest (memory safety)
local CONFIG = {
  namespace_name = '_rain',
  chars = { '⋅', '•' },
  diagonal_chars = { '', '◇', '' },
  drop_count = 5,
  spawn_interval = 500,
  drop_interval = 40,
  initial_delay = 1000,
  winblend = 100,
  speed_variance = 15,
  diagonal_chance = 1,
  max_concurrent_drops = 200,
}

---@class RainDrop
---@field timer userdata libuv timer handle for this drop's animation
---@field extmark_id integer Extmark ID for the drop's visual representation
---@field buf integer Buffer handle where the drop is rendered
---@field row integer Current row position (0-indexed)
---@field col integer Current column position (0-indexed)

---@class RainState
---@field namespace integer|nil Extmark namespace ID
---@field global_timer userdata|nil Main spawn timer (libuv handle)
---@field window integer|nil Floating window handle
---@field buffer integer|nil Scratch buffer handle
---@field drops RainDrop[] Active drops with their timers and positions
---@field is_running boolean Animation state flag
---@field _chars_configured boolean One-time char setup flag
---@field _autocmds integer[] Autocmd IDs for cleanup on stop
local STATE = {
  namespace = nil,
  global_timer = nil,
  window = nil,
  buffer = nil,
  drops = {},
  is_running = false,
  _chars_configured = false,
  _autocmds = {},
}

local api = vim.api

---Safely close a libuv timer handle.
---
---PATTERN: Always check is_closing() before stop()/close() to avoid
---double-free errors. This is the standard cleanup pattern for vim.uv handles.
---
---@param timer userdata|nil The libuv timer handle to clean up
local function cleanup_timer(timer)
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
end

---Calculate available screen dimensions for the rain window.
---
---Accounts for statusline and cmdheight to avoid overlapping UI elements.
---Returns dimensions suitable for nvim_open_win() and buffer line count.
---
---@return { width: integer, height: integer }
local function get_rain_dimensions()
  local available_lines = vim.o.lines

  -- Subtract statusline if visible (laststatus > 0)
  if vim.o.laststatus > 0 then
    available_lines = available_lines - 1
  end

  -- Subtract command line height
  available_lines = available_lines - vim.o.cmdheight
  available_lines = math.max(1, available_lines)

  return {
    width = vim.o.columns,
    height = available_lines,
  }
end

---Generate a weighted random column biased toward the left side.
---
---Uses quadratic weighting (rand^2) to create a natural "rain from top-left"
---effect. Can spawn slightly off-screen (negative) to allow diagonal drops
---to enter the visible area.
---
---@param max_col integer Maximum column index
---@return integer Column position (may be negative for off-screen spawn)
local function get_weighted_column(max_col)
  local max_index = math.max(0, max_col)
  local rand = math.random()
  local weighted = rand * rand -- Quadratic bias toward 0
  local offset = -math.floor(max_index / 4) -- Allow negative (off-screen left)
  local raw = math.floor(weighted * (max_index - offset)) + offset
  return math.max(offset, math.min(max_index, raw))
end

---Remove a drop from tracking and clean up its timer.
---
---@param idx integer Index in STATE.drops to remove
local function remove_drop(idx)
  if STATE.drops[idx] then
    cleanup_timer(STATE.drops[idx].timer)
    table.remove(STATE.drops, idx)
  end
end

---Find drop index by its timer handle.
---
---Searches in reverse order since newer drops are more likely to be
---the ones being cleaned up (temporal locality).
---
---@param timer userdata The timer handle to find
---@return integer|nil Index in STATE.drops or nil if not found
local function find_drop_by_timer(timer)
  for i = #STATE.drops, 1, -1 do
    if STATE.drops[i] and STATE.drops[i].timer == timer then
      return i
    end
  end
  return nil
end

---Clean up all rain resources: timers, window, buffer, autocmds.
---
---Called on M.stop() and on errors during M.rain() initialization.
---Ensures no resource leaks even if called multiple times.
local function cleanup_all()
  -- Stop global spawn timer
  cleanup_timer(STATE.global_timer)
  STATE.global_timer = nil

  -- Stop all drop animation timers (reverse iteration for safe removal)
  for i = #STATE.drops, 1, -1 do
    cleanup_timer(STATE.drops[i].timer)
  end
  STATE.drops = {}

  -- Close floating window
  if STATE.window and api.nvim_win_is_valid(STATE.window) then
    api.nvim_win_close(STATE.window, true)
  end
  STATE.window = nil

  -- Delete scratch buffer (clears extmarks automatically)
  if STATE.buffer and api.nvim_buf_is_valid(STATE.buffer) then
    api.nvim_buf_clear_namespace(STATE.buffer, STATE.namespace, 0, -1)
    api.nvim_buf_delete(STATE.buffer, { force = true })
  end
  STATE.buffer = nil

  -- Remove autocmds we created
  for _, id in ipairs(STATE._autocmds) do
    pcall(api.nvim_del_autocmd, id)
  end
  STATE._autocmds = {}
end

---Create a scratch buffer filled with spaces for rain rendering.
---
---The buffer is unlisted (won't appear in :ls) and scratch (no file backing).
---Pre-filled with spaces so extmarks can be placed at any position.
---
---@return integer Buffer handle
local function create_rain_buffer()
  -- Create unlisted scratch buffer
  -- nvim_create_buf(listed, scratch) -> listed=false, scratch=true
  local buf = api.nvim_create_buf(false, true)

  local dims = get_rain_dimensions()
  local pad_line = string.rep(' ', dims.width)
  local lines = {}
  for _ = 1, dims.height do
    lines[#lines + 1] = pad_line
  end
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  return buf
end

---Create a floating window covering the editor for rain display.
---
---Window properties:
--- - relative="editor": Position relative to editor, not cursor/window
--- - style="minimal": No line numbers, fold columns, etc.
--- - focusable=false: Prevent user from accidentally focusing
--- - zindex=1: Render behind everything else
---
---@param buf integer Buffer to display in the window
---@return integer Window handle
local function create_rain_window(buf)
  local dims = get_rain_dimensions()

  local win = api.nvim_open_win(buf, false, {
    relative = 'editor',
    style = 'minimal',
    border = 'none',
    width = dims.width,
    height = dims.height,
    row = 0,
    col = 0,
    focusable = false,
    zindex = 1,
  })

  -- Make background transparent
  pcall(vim.cmd, 'highlight NormalFloat guibg=none')
  vim.wo[win].winblend = CONFIG.winblend

  return win
end

---Adjust rain window and buffer when terminal is resized.
---
---Handles VimResized event to keep rain covering the full screen.
---Resizes buffer content and window dimensions to match new size.
local function adjust_rain_window()
  if not STATE.is_running or not STATE.window or not api.nvim_win_is_valid(STATE.window) then
    return
  end

  local dims = get_rain_dimensions()

  -- Update window dimensions
  pcall(api.nvim_win_set_config, STATE.window, {
    relative = 'editor',
    width = dims.width,
    height = dims.height,
    row = 0,
    col = 0,
    focusable = false,
    zindex = 1,
  })

  -- Resize buffer content to match
  local ok, lines = pcall(api.nvim_buf_get_lines, STATE.buffer, 0, -1, false)
  if not ok then
    return
  end

  local new_lines = {}
  local pad_line = string.rep(' ', dims.width)
  for i = 1, dims.height do
    if i <= #lines then
      local line = lines[i] or pad_line
      -- Pad or truncate line to new width
      if #line < dims.width then
        line = line .. string.rep(' ', dims.width - #line)
      elseif #line > dims.width then
        line = line:sub(1, dims.width)
      end
      new_lines[i] = line
    else
      new_lines[i] = pad_line
    end
  end
  pcall(api.nvim_buf_set_lines, STATE.buffer, 0, -1, false, new_lines)
end

---Create and animate a single raindrop.
---
---Each drop has its own libuv timer that moves it down (and optionally
---diagonally) at CONFIG.drop_interval + random variance.
---
---EXTMARK ANIMATION PATTERN:
---  1. Create extmark at initial position with virt_text
---  2. Start timer with vim.schedule_wrap callback
---  3. In callback: update extmark position by passing same ID
---  4. When drop exits screen: delete extmark, stop timer, remove from tracking
---
---@param buf integer Buffer to render the drop in
---@param start_col integer Starting column (may be negative for off-screen)
---@param char string Character to display for this drop
---@param move_diagonally boolean Whether drop moves diagonally (down+right)
local function create_single_raindrop(buf, start_col, char, move_diagonally)
  local row, col = 0, start_col

  -- Handle off-screen spawn (negative col): start at row that brings it on-screen
  if col < 0 then
    row = row - col
    col = 0
  end

  local dims = get_rain_dimensions()
  if row >= dims.height then
    return
  end

  -- Create initial extmark (visual representation of drop)
  local init_col = math.max(0, math.min(col, dims.width - 1))
  local ok, extmark_id = pcall(api.nvim_buf_set_extmark, buf, STATE.namespace, row, init_col, {
    virt_text = { { char, 'Identifier' } },
    virt_text_pos = 'overlay',
  })
  if not ok then
    return
  end

  -- MEMORY SAFETY: Evict oldest drop if at capacity
  -- Prevents unbounded memory growth if drops spawn faster than they exit
  if #STATE.drops >= CONFIG.max_concurrent_drops then
    local oldest = STATE.drops[1]
    if oldest then
      pcall(api.nvim_buf_del_extmark, oldest.buf, STATE.namespace, oldest.extmark_id)
      remove_drop(1)
    end
  end

  -- Calculate speed with random variance for natural effect
  local speed = math.max(10, CONFIG.drop_interval + math.random(-CONFIG.speed_variance, CONFIG.speed_variance))

  -- Create animation timer for this drop
  local timer = vim.uv.new_timer()
  if not timer then
    pcall(api.nvim_buf_del_extmark, buf, STATE.namespace, extmark_id)
    return
  end

  -- Track this drop (unified: timer + extmark + position)
  local drop = { timer = timer, extmark_id = extmark_id, buf = buf, row = row, col = col }
  STATE.drops[#STATE.drops + 1] = drop

  -- Start animation loop
  -- timer:start(delay, repeat, callback)
  -- delay=0: Start immediately, repeat=speed: Run every 'speed' ms
  timer:start(
    0,
    speed,
    vim.schedule_wrap(function()
      local cur_dims = get_rain_dimensions()

      -- Exit conditions: stopped, invalid buffer, or drop exited screen
      if not STATE.is_running or not api.nvim_buf_is_valid(buf) or drop.row >= cur_dims.height or drop.col >= cur_dims.width then
        pcall(api.nvim_buf_del_extmark, buf, STATE.namespace, extmark_id)
        local idx = find_drop_by_timer(timer)
        if idx then
          remove_drop(idx)
        else
          cleanup_timer(timer)
        end
        return
      end

      -- Update extmark position (pass same ID to move existing mark)
      local clipped_col = math.max(0, math.min(drop.col, cur_dims.width - 1))
      local ok_update = pcall(api.nvim_buf_set_extmark, buf, STATE.namespace, drop.row, clipped_col, {
        virt_text = { { char, 'Identifier' } },
        virt_text_pos = 'overlay',
        id = extmark_id, -- Reuse ID = update position
      })

      if ok_update then
        drop.row = drop.row + 1
        drop.col = drop.col + (move_diagonally and 1 or 0)
      else
        -- Extmark update failed, clean up this drop
        pcall(api.nvim_buf_del_extmark, buf, STATE.namespace, extmark_id)
        local idx = find_drop_by_timer(timer)
        if idx then
          remove_drop(idx)
        else
          cleanup_timer(timer)
        end
      end
    end)
  )
end

---Start the rain animation.
---
---Creates a full-screen floating window with a transparent background and
---starts spawning animated raindrops at CONFIG.spawn_interval.
---
---Safe to call multiple times (no-op if already running).
function M.rain()
  if STATE.is_running then
    return
  end

  STATE.namespace = STATE.namespace or api.nvim_create_namespace(CONFIG.namespace_name)

  -- Create window and buffer with error handling
  local ok, err = pcall(function()
    STATE.buffer = create_rain_buffer()
    STATE.window = create_rain_window(STATE.buffer)
  end)

  if not ok then
    vim.notify('Failed to create rain: ' .. tostring(err), vim.log.levels.ERROR)
    cleanup_all()
    return
  end

  STATE.is_running = true

  -- Handle terminal resize
  STATE._autocmds[#STATE._autocmds + 1] = api.nvim_create_autocmd('VimResized', {
    callback = adjust_rain_window,
  })

  -- Cleanup on Neovim exit (prevent timer leaks)
  STATE._autocmds[#STATE._autocmds + 1] = api.nvim_create_autocmd('VimLeavePre', {
    callback = M.stop,
    once = true,
  })

  -- Create main spawn timer
  STATE.global_timer = vim.uv.new_timer()
  if not STATE.global_timer then
    M.stop()
    return
  end

  -- Spawn loop: create CONFIG.drop_count drops every CONFIG.spawn_interval ms
  STATE.global_timer:start(
    CONFIG.initial_delay,
    CONFIG.spawn_interval,
    vim.schedule_wrap(function()
      if not STATE.is_running or not api.nvim_buf_is_valid(STATE.buffer) then
        return
      end

      local dims = get_rain_dimensions()

      for _ = 1, CONFIG.drop_count do
        -- Stagger spawns within the interval for natural effect
        local spawn_delay = math.random(0, CONFIG.spawn_interval - 50)
        local move_diagonally = math.random() < CONFIG.diagonal_chance
        local char_pool = move_diagonally and CONFIG.diagonal_chars or CONFIG.chars
        local char = char_pool[math.random(1, #char_pool)]

        if spawn_delay > 0 then
          -- Use vim.defer_fn for simple one-shot delays (no manual cleanup needed)
          vim.defer_fn(function()
            if STATE.is_running and api.nvim_buf_is_valid(STATE.buffer) then
              local cur_dims = get_rain_dimensions()
              local start_col = get_weighted_column(cur_dims.width - 1)
              create_single_raindrop(STATE.buffer, start_col, char, move_diagonally)
            end
          end, spawn_delay)
        else
          local start_col = get_weighted_column(dims.width - 1)
          create_single_raindrop(STATE.buffer, start_col, char, move_diagonally)
        end
      end
    end)
  )
end

---Stop the rain animation and clean up all resources.
---
---Stops all timers, closes the window, deletes the buffer, and removes
---autocmds. Safe to call multiple times.
function M.stop()
  STATE.is_running = false
  cleanup_all()
end

---Toggle rain animation on/off.
function M.toggle()
  if STATE.is_running then
    M.stop()
  else
    M.rain()
  end
end

---Check if rain animation is currently running.
---@return boolean
function M.is_running()
  return STATE.is_running
end

-- Safety: stop any running animation if module is reloaded
if STATE.is_running then
  M.stop()
end

---Initialize the rain module with optional config overrides.
---
---Sets up the :Rain command and VimEnter autocmd to start rain on launch.
---Rain stops automatically when entering a non-snacks buffer.
---
---@param user_config RainConfig|nil Optional configuration overrides
---@return table The module (for chaining)
function M.setup(user_config)
  -- Reset namespace on setup (allows re-configuration)
  STATE.namespace = nil

  -- Clean up any existing autocmds from previous setup
  for _, id in ipairs(STATE._autocmds) do
    pcall(api.nvim_del_autocmd, id)
  end
  STATE._autocmds = {}

  -- Merge user config
  if user_config then
    for key, value in pairs(user_config) do
      if CONFIG[key] ~= nil then
        CONFIG[key] = value
      end
    end
  end

  -- Add pipe character to chars pool (one-time)
  if not STATE._chars_configured then
    CONFIG.chars[#CONFIG.chars + 1] = CONFIG.diagonal_chance and '' or '|'
    STATE._chars_configured = true
  end

  STATE.namespace = api.nvim_create_namespace(CONFIG.namespace_name)

  -- Create :Rain command
  api.nvim_create_user_command('Rain', M.toggle, { desc = 'Toggle rain animation', force = true })

  -- Start rain on VimEnter, stop when leaving snacks dashboard
  local vim_enter_id = api.nvim_create_autocmd('VimEnter', {
    callback = function()
      M.rain()
      local buf_enter_id = api.nvim_create_autocmd('BufEnter', {
        callback = function(ev)
          -- Stay running on snacks dashboard buffers
          if vim.bo[ev.buf].filetype:match '^snacks_' then
            return
          end
          M.stop()
        end,
      })
      STATE._autocmds[#STATE._autocmds + 1] = buf_enter_id
    end,
    once = true,
  })
  STATE._autocmds[#STATE._autocmds + 1] = vim_enter_id

  return M
end

return M
