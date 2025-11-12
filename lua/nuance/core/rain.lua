---@meta
---Rain animation module for Neovim.
---
---Provides a rain particle effect displayed as virtual text in an overlay window.
---Features include:
---  - Particles spawn off-screen on the left and fall diagonally right
---  - Natural accumulation in the bottom-left corner
---  - Configurable particle characters, speeds, and animation timings
---  - Automatic cleanup on buffer entry and script reload
---
---## Usage
---
---```lua
---local rain = require('nuance.core.rain')
---
----- Optional: Configure before setup
---rain.setup({
---  drop_count = 10,
---  spawn_interval = 400,
---  diagonal_chance = 1,
---})
---
---rain.rain()    -- Start animation
---rain.stop()    -- Stop animation
---rain.toggle()  -- Toggle on/off
---```
---
---## Configuration
---
---Customize the animation by passing options to `setup()`:
---
---```lua
---{
---  chars = { '⋅', '•' },              -- Characters for vertical movement
---  diagonal_chars = { '◇', '◆' },     -- Characters for diagonal movement
---  drop_count = 5,                     -- Drops per spawn batch
---  spawn_interval = 500,               -- ms between spawn batches
---  drop_interval = 40,                 -- ms between raindrop position updates
---  initial_delay = 1000,               -- ms before first spawn
---  winblend = 100,                     -- Window transparency (0-100)
---  speed_variance = 15,                -- ±ms variance in drop speed
---  diagonal_chance = 1,                -- Probability of diagonal movement (0-1)
---}
---```
local M = {}

---@class RainDimensions
---@field width integer Screen width in columns
---@field height integer Available height for rain
---@field max_row integer Maximum row index (height - 1)
---@field max_col integer Maximum column index (width - 1)

---@class RainDropState
---@field row integer Current line (row) position
---@field col integer Current column position

---@class RainConfig
---@field namespace_name string Namespace identifier for extmarks
---@field chars string[] Characters used for straight-down movement
---@field diagonal_chars string[] Characters used for diagonal movement
---@field drop_count integer Number of drops per spawn batch
---@field spawn_interval integer Milliseconds between spawn batches
---@field drop_interval integer Milliseconds between drop position updates
---@field initial_delay integer Milliseconds before first spawn
---@field winblend integer Window blend level (0-100, higher = more transparent)
---@field speed_variance integer ±milliseconds variance in drop speed
---@field diagonal_chance number Probability drops move diagonally (0.0-1.0)

---@class RainState
---@field namespace integer? Neovim namespace ID for extmarks
---@field global_timer uv.uv_timer_t? Timer for spawning batches
---@field window integer? Window ID for rain display
---@field buffer integer? Buffer ID for rain display
---@field drop_timers uv.uv_timer_t[] List of active drop timers
---@field is_running boolean Whether animation is currently active
---@field _chars_configured boolean Internal flag to prevent duplicate config on reload
---@field _dimensions_cache RainDimensions? Cached window dimensions to avoid vim.o reads
---@field _dimensions_stale boolean Flag indicating cache needs refresh on VimResized

-- Configuration with defaults
---@type RainConfig
local CONFIG = {
  namespace_name = '_rain',
  chars = { '⋅', '•' },
  diagonal_chars = { '◇', '' }, -- Characters used for diagonal movement
  drop_count = 5,
  spawn_interval = 500, -- ms - how often to spawn new batches
  drop_interval = 40, -- ms - how fast drops fall
  initial_delay = 1000, -- ms - delay before first spawn
  winblend = 100,
  -- Additional randomization factors
  speed_variance = 15, -- ±15ms variance in drop speed
  diagonal_chance = 1,
}

-- State management
---@type RainState
local STATE = {
  namespace = nil,
  global_timer = nil,
  window = nil,
  buffer = nil,
  drop_timers = {},
  is_running = false,
  _chars_configured = false, -- FIXED: prevent duplicate char insertion on reload
  _dimensions_cache = nil, -- OPT-P2: cached dimensions to reduce vim.o reads
  _dimensions_stale = false, -- OPT-P2: marks cache as needing refresh
}

---Check if a window ID is valid and still exists.
---@param win integer? Window ID to validate
---@return boolean
local function is_valid_window(win)
  return win and vim.api.nvim_win_is_valid(win)
end

---Check if a buffer ID is valid and still exists.
---@param buf integer? Buffer ID to validate
---@return boolean
local function is_valid_buffer(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

---Generate a weighted random column for raindrop spawning.
---
---Applies exponential weighting to bias spawn positions toward the left side.
---Returns values in range [-width/4, width] to enable off-screen left spawning.
---Particles spawned off-screen have their starting row adjusted by the negative
---column offset, causing them to accumulate naturally in the bottom-left corner
---as they fall diagonally right.
---
---@param max_col integer Maximum column index
---@return integer Weighted column position (may be negative for off-screen)
local function get_weighted_column(max_col)
  local rand = math.random() -- Generate random value between 0 and 1
  -- Apply exponential weighting: square the random value to bias towards lower values
  local weighted = math.pow(rand, 2)
  -- Map to range [-max_col/4, max_col] to allow off-screen left spawning
  -- This creates natural accumulation: off-screen particles move right while falling
  local offset = -math.floor(max_col / 4)
  return math.floor(weighted * (max_col - offset)) + offset
end

---Safely close and clean up a timer.
---
---Checks if timer is not already closing before stopping and closing.
---Prevents errors from double-closing or closing invalid timers.
---
---@param timer uv.uv_timer_t? Timer to clean up
local function cleanup_timer(timer)
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
end

---Clean up all active timers (global and drops).
---
---Stops and closes both the global spawn timer and all individual drop timers.
---Clears the drop_timers list after cleanup.
local function cleanup_all_timers()
  -- Clean up global timer
  cleanup_timer(STATE.global_timer)
  STATE.global_timer = nil

  -- Clean up all drop timers
  for _, timer in ipairs(STATE.drop_timers) do
    cleanup_timer(timer)
  end
  STATE.drop_timers = {}
end

---Remove a specific timer from the drop_timers tracking list.
---
---Searches in reverse order to safely remove during iteration.
---
---@param timer_to_remove uv.uv_timer_t Timer to remove
local function remove_timer(timer_to_remove)
  for i = #STATE.drop_timers, 1, -1 do
    if STATE.drop_timers[i] == timer_to_remove then
      table.remove(STATE.drop_timers, i)
      break
    end
  end
end

---Close the rain window and delete the rain buffer.
---
---Clears all extmarks in the namespace before buffer deletion.
---Sets window and buffer state to nil after cleanup.
local function cleanup_window_and_buffer()
  -- Close window
  if is_valid_window(STATE.window) then
    vim.api.nvim_win_close(STATE.window, true)
  end
  STATE.window = nil

  -- Delete buffer
  if is_valid_buffer(STATE.buffer) then
    vim.api.nvim_buf_clear_namespace(STATE.buffer, STATE.namespace, 0, -1)
    vim.api.nvim_buf_delete(STATE.buffer, { force = true })
  end
  STATE.buffer = nil
end

---Invalidate dimension cache on resize events.
---
---Called when VimResized event fires to mark cache as stale.
---Next call to get_rain_dimensions() will recalculate.
local function invalidate_dimensions_cache()
  STATE._dimensions_stale = true
end

---Calculate available rain dimensions based on window size.
---
---Subtracts statusline height (if visible) and cmdline height from total lines.
---Ensures at least 1 line is available for rain display.
---
---OPT-P2: Caches result and only recalculates when dimensions_stale flag is true
---or cache is nil. Cache is invalidated on VimResized event.
---
---@return RainDimensions Dimensions table with width, height, max_row, max_col
local function get_rain_dimensions()
  -- OPT-P2: Return cached dimensions if valid
  if STATE._dimensions_cache and not STATE._dimensions_stale then
    return STATE._dimensions_cache
  end

  -- Calculate available space excluding statusline and command line
  local total_lines = vim.o.lines
  local available_lines = total_lines

  -- Subtract statusline height if enabled
  if vim.o.laststatus > 0 then
    available_lines = available_lines - 1
  end

  -- Subtract command line height
  available_lines = available_lines - vim.o.cmdheight

  -- Ensure we have at least some space for rain
  available_lines = math.max(1, available_lines)

  -- OPT-P2: Cache the result
  STATE._dimensions_cache = {
    width = vim.o.columns,
    height = available_lines,
    max_row = available_lines - 1,
    max_col = vim.o.columns - 1,
  }
  STATE._dimensions_stale = false

  return STATE._dimensions_cache
end

---Create a new buffer for displaying rain animation.
---
---Creates a scratch buffer initialized with empty lines matching the rain display area.
---
---@return integer Buffer ID
local function create_rain_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  if not buf then
    error 'Failed to create buffer'
  end

  local dimensions = get_rain_dimensions()

  -- Initialize buffer with empty spaces (only for the rain area)
  local lines = {}
  for _ = 1, dimensions.height do
    table.insert(lines, string.rep(' ', dimensions.width))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  return buf
end

---Create a floating window for the rain display.
---
---Creates a minimal floating window covering the entire editor area.
---Window is focusable=false and positioned at zindex=1 to stay behind other windows.
---
---@param buf integer Buffer ID to display in the window
---@return integer Window ID
local function create_rain_window(buf)
  local dimensions = get_rain_dimensions()

  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    style = 'minimal',
    border = 'none',
    width = dimensions.width,
    height = dimensions.height,
    row = 0,
    col = 0,
    focusable = false,
    zindex = 1,
  })

  if not win then
    error 'Failed to create window'
  end

  -- Configure window appearance
  pcall(vim.cmd, 'highlight NormalFloat guibg=none')
  vim.wo[win].winblend = CONFIG.winblend

  return win
end

---Create and animate a single raindrop.
---
---Spawns a raindrop at the given starting column with the specified character.
---Handles off-screen left spawning by adjusting the starting row.
---Moves the raindrop down (and optionally right) each frame until it reaches bottom/right edge.
---
---Movement Pattern:
---  - Vertical: Always moves down 1 line per update
---  - Horizontal: Moves right 1 column per update if move_diagonally is true
---
---Off-Screen Spawning:
---  - If start_col < 0, adds |start_col| to start_row and clamps col to 0
---  - This creates natural accumulation in bottom-left as particles fall
---
---OPT-P3: move_diagonally is now passed as parameter instead of recalculated
---
---@param buf integer Buffer ID to draw raindrop in
---@param start_col integer Starting column (may be negative for off-screen)
---@param char string Character to display for this raindrop
---@param move_diagonally boolean Whether this drop moves diagonally
---@return uv.uv_timer_t? Timer handle if creation succeeded, nil on failure
local function create_single_raindrop(buf, start_col, char, move_diagonally)
  ---@type RainDropState
  local drop_state = { row = 0, col = start_col }

  -- Handle off-screen left spawning: if start_col is negative,
  -- add it to start row and clamp column to 0
  if drop_state.col < 0 then
    drop_state.row = drop_state.row - drop_state.col -- Add negative value (increases row)
    drop_state.col = 0
  end

  local speed_variance = math.random(-CONFIG.speed_variance, CONFIG.speed_variance)
  local actual_speed = math.max(10, CONFIG.drop_interval + speed_variance)

  -- Create initial extmark
  local ok, extmark_id = pcall(vim.api.nvim_buf_set_extmark, buf, STATE.namespace, drop_state.row, drop_state.col, {
    virt_text = { { char, 'Identifier' } },
    virt_text_pos = 'overlay',
  })

  if not ok then
    return nil
  end

  -- Create timer for this specific raindrop
  local drop_timer = vim.uv.new_timer()
  if not drop_timer then
    pcall(vim.api.nvim_buf_del_extmark, buf, STATE.namespace, extmark_id)
    return nil
  end

  table.insert(STATE.drop_timers, drop_timer)

  drop_timer:start(
    0,
    actual_speed,
    vim.schedule_wrap(function()
      local current_dimensions = get_rain_dimensions()
      -- Check if raindrop should stop (reached bottom or right edge)
      if
        not STATE.is_running
        or not is_valid_buffer(buf)
        or drop_state.row >= current_dimensions.height
        or drop_state.col >= current_dimensions.width
      then
        -- Clean up extmark and timer
        pcall(vim.api.nvim_buf_del_extmark, buf, STATE.namespace, extmark_id)
        cleanup_timer(drop_timer)
        -- Remove from tracking list
        remove_timer(drop_timer)
        return
      end

      -- Update raindrop position
      local ok_update = pcall(vim.api.nvim_buf_set_extmark, buf, STATE.namespace, drop_state.row, drop_state.col, {
        virt_text = { { char, 'Identifier' } },
        virt_text_pos = 'overlay',
        id = extmark_id,
      })

      if ok_update then
        drop_state.row = drop_state.row + 1
        -- Some drops move diagonally, others straight down
        drop_state.col = drop_state.col + (move_diagonally and 1 or 0)
      else
        -- Failed to update, clean up
        pcall(vim.api.nvim_buf_del_extmark, buf, STATE.namespace, extmark_id)
        cleanup_timer(drop_timer)
        remove_timer(drop_timer)
      end
    end)
  )

  return drop_timer
end

---Start the rain animation.
---
---Creates the buffer and window, starts the global timer for spawning raindrop batches.
---Does nothing if animation is already running.
---
---On error, stops the animation and cleans up resources.
---
---OPT-P1: Uses vim.defer_fn() instead of spawn timers for better performance.
---Replace individual spawn timers with deferred function calls that execute
---immediately (no delay) but don't create new timer objects. Saves 50-200 timers/sec.
---
---OPT-P2: Sets up VimResized autocommand to invalidate dimension cache.
---
---@return nil
function M.rain()
  if STATE.is_running then
    print 'Rain animation is already running'
    return
  end

  -- Initialize namespace
  if not STATE.namespace then
    STATE.namespace = vim.api.nvim_create_namespace(CONFIG.namespace_name)
  end

  -- Create buffer and window
  local ok, result = pcall(function()
    STATE.buffer = create_rain_buffer()
    STATE.window = create_rain_window(STATE.buffer)
  end)

  if not ok then
    vim.notify('Failed to create rain animation: ' .. tostring(result), vim.log.levels.ERROR)
    M.stop()

    -- Ensure buffer cleanup
    if STATE.buffer and vim.api.nvim_buf_is_valid(STATE.buffer) then
      vim.api.nvim_buf_delete(STATE.buffer, { force = true })
    end
    STATE.buffer = nil
    return
  end

  STATE.is_running = true

  -- OPT-P2: Set up VimResized event to invalidate dimension cache
  vim.api.nvim_create_autocmd('VimResized', {
    callback = invalidate_dimensions_cache,
    once = false,
  })

  -- Create global timer for spawning raindrop batches (like the original)
  STATE.global_timer = vim.uv.new_timer()
  if not STATE.global_timer then
    print 'Failed to create global timer'
    M.stop()
    return
  end

  STATE.global_timer:start(
    CONFIG.initial_delay,
    CONFIG.spawn_interval,
    vim.schedule_wrap(function()
      if not STATE.is_running or not is_valid_buffer(STATE.buffer) then
        return
      end

      local dimensions = get_rain_dimensions()

      -- Create raindrops with staggered spawn times for more natural effect
      for i = 1, CONFIG.drop_count do
        local spawn_delay = math.random(0, CONFIG.spawn_interval - 50) -- Random delay within spawn interval
        local start_col = get_weighted_column(math.max(1, dimensions.width)) -- Use weighted distribution with off-screen left spawning

        -- Determine if this raindrop will move diagonally
        local move_diagonally = math.random() < CONFIG.diagonal_chance

        -- Select character based on movement direction
        local char_pool = move_diagonally and CONFIG.diagonal_chars or CONFIG.chars
        local char = char_pool[math.random(1, #char_pool)]

        -- OPT-P1: Use vim.defer_fn() instead of creating spawn timers
        if spawn_delay > 0 then
          -- Defer the spawn if we need a delay
          vim.defer_fn(function()
            if STATE.is_running and is_valid_buffer(STATE.buffer) then
              create_single_raindrop(STATE.buffer, start_col, char, move_diagonally)
            end
          end, spawn_delay)
        else
          -- OPT-P1 + OPT-P3: If no delay, create immediately and pass move_diagonally
          if STATE.is_running and is_valid_buffer(STATE.buffer) then
            create_single_raindrop(STATE.buffer, start_col, char, move_diagonally)
          end
        end
      end
    end)
  )
end

---Stop the rain animation.
---
---Sets is_running to false, cleans up all timers, window, and buffer.
---Also performs a fallback cleanup of any orphaned rain buffers.
---
---Safe to call even if animation is not running.
---
---@return nil
function M.stop()
  STATE.is_running = false

  -- Clean up all timers
  cleanup_all_timers()

  -- Clean up window and buffer
  cleanup_window_and_buffer()

  -- Clean up any orphaned rain buffers (fallback)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_valid_buffer(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      -- OPT-P4: Use :sub() instead of :match() for string checking
      if buf_name:sub(1, #CONFIG.namespace_name) == CONFIG.namespace_name then
        pcall(vim.api.nvim_buf_clear_namespace, buf, STATE.namespace, 0, -1)
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end
end

---Toggle the rain animation on or off.
---
---If running, stops it. Otherwise, starts it.
---
---@return nil
function M.toggle()
  if STATE.is_running then
    M.stop()
  else
    M.rain()
  end
end

---Check if the rain animation is currently running.
---
---@return boolean True if animation is active, false otherwise
function M.is_running()
  return STATE.is_running
end

-- Clean up on script reload
if STATE.is_running then
  M.stop()
end

---Initialize the rain module with optional configuration.
---
---Sets up user commands and autocommands for the rain animation.
---Creates a ':Rain' command to toggle animation.
---Automatically starts rain on VimEnter and stops when entering special buffers.
---
---Configuration is merged with defaults, allowing partial overrides.
---Only the first call to setup() will add extra characters to the config.
---
---@param user_config RainConfig? Optional configuration table
---@return table Module table (M)
function M.setup(user_config)
  -- Clean up old namespace if exists
  if STATE.namespace then
    pcall(function()
      vim.api.nvim_get_namespaces()[STATE.namespace] = nil
    end)
  end

  -- Merge user config
  if user_config then
    for key, value in pairs(user_config) do
      if CONFIG[key] ~= nil then
        CONFIG[key] = value
      end
    end
  end

  -- FIXED: Only add character to config.chars once on setup
  if not STATE._chars_configured then
    table.insert(CONFIG.chars, CONFIG.diagonal_chance and '' or '|')
    STATE._chars_configured = true
  end

  -- Ensure namespace is created
  if not STATE.namespace then
    STATE.namespace = vim.api.nvim_create_namespace(CONFIG.namespace_name)
  end

  vim.api.nvim_create_user_command('Rain', M.toggle, {
    desc = 'Toggle rain animation',
    force = true,
  })

  vim.api.nvim_create_autocmd('VimEnter', {
    callback = function()
      M.rain()
      vim.api.nvim_create_autocmd('BufEnter', {
        callback = function(ev)
          if vim.bo[ev.buf].filetype:match '^snacks_' then
            return
          end
          M.stop()
        end,
      })
    end,
    once = true,
  })

  return M
end

return M
