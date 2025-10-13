local M = {}

-- Configuration
local config = {
  namespace_name = '_rain',
  chars = { '⋅', '•' },
  drop_count = 5,
  spawn_interval = 500, -- ms - how often to spawn new batches
  drop_interval = 35, -- ms - how fast drops fall
  initial_delay = 1000, -- ms - delay before first spawn
  winblend = 100,
  -- Additional randomization factors
  speed_variance = 15, -- ±15ms variance in drop speed
  diagonal_chance = 1,
}

-- State management
local state = {
  namespace = nil,
  global_timer = nil,
  window = nil,
  buffer = nil,
  drop_timers = {},
  is_running = false,
}

-- Utility functions
local function is_valid_window(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buffer(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function cleanup_timer(timer)
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
end

local function cleanup_all_timers()
  -- Clean up global timer
  cleanup_timer(state.global_timer)
  state.global_timer = nil

  -- Clean up all drop timers
  for _, timer in ipairs(state.drop_timers) do
    cleanup_timer(timer)
  end
  state.drop_timers = {}
end

local function cleanup_window_and_buffer()
  -- Close window
  if is_valid_window(state.window) then
    vim.api.nvim_win_close(state.window, true)
  end
  state.window = nil

  -- Delete buffer
  if is_valid_buffer(state.buffer) then
    vim.api.nvim_buf_clear_namespace(state.buffer, state.namespace, 0, -1)
    vim.api.nvim_buf_delete(state.buffer, { force = true })
  end
  state.buffer = nil
end

local function get_rain_dimensions()
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

  return {
    width = vim.o.columns,
    height = available_lines,
    max_row = available_lines - 1,
    max_col = vim.o.columns - 1,
  }
end

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
  vim.cmd 'highlight NormalFloat guibg=none'
  vim.wo[win].winblend = config.winblend

  return win
end

local function create_single_raindrop(buf, start_col, char)
  local drop_state = { l = 0, c = start_col }

  -- Add randomization to movement pattern
  local move_diagonally = math.random() < config.diagonal_chance
  local speed_variance = math.random(-config.speed_variance, config.speed_variance)
  local actual_speed = math.max(10, config.drop_interval + speed_variance)

  -- Create initial extmark
  local ok, extmark_id = pcall(vim.api.nvim_buf_set_extmark, buf, state.namespace, drop_state.l, drop_state.c, {
    virt_text = { { char, 'Identifier' } },
    virt_text_pos = 'overlay',
  })

  if not ok then
    return nil
  end

  -- Create timer for this specific raindrop
  local drop_timer = vim.uv.new_timer()
  if not drop_timer then
    pcall(vim.api.nvim_buf_del_extmark, buf, state.namespace, extmark_id)
    return nil
  end

  table.insert(state.drop_timers, drop_timer)

  drop_timer:start(
    0,
    actual_speed,
    vim.schedule_wrap(function()
      local current_dimensions = get_rain_dimensions()

      -- Check if raindrop should stop (reached bottom or right edge)
      if
        not state.is_running
        or not is_valid_buffer(buf)
        or drop_state.l >= current_dimensions.height
        or drop_state.c >= current_dimensions.width
      then
        -- Clean up extmark and timer
        pcall(vim.api.nvim_buf_del_extmark, buf, state.namespace, extmark_id)
        cleanup_timer(drop_timer)
        -- Remove from tracking list
        for i, timer in ipairs(state.drop_timers) do
          if timer == drop_timer then
            table.remove(state.drop_timers, i)
            break
          end
        end
        return
      end

      -- Update raindrop position
      local ok_update = pcall(vim.api.nvim_buf_set_extmark, buf, state.namespace, drop_state.l, drop_state.c, {
        virt_text = { { char, 'Identifier' } },
        virt_text_pos = 'overlay',
        id = extmark_id,
      })

      if ok_update then
        drop_state.l = drop_state.l + 1
        -- Some drops move diagonally, others straight down
        drop_state.c = drop_state.c + (move_diagonally and 1 or 0)
      else
        -- Failed to update, clean up
        pcall(vim.api.nvim_buf_del_extmark, buf, state.namespace, extmark_id)
        cleanup_timer(drop_timer)
        for i, timer in ipairs(state.drop_timers) do
          if timer == drop_timer then
            table.remove(state.drop_timers, i)
            break
          end
        end
      end
    end)
  )

  return drop_timer
end

-- Public API
function M.rain()
  if state.is_running then
    print 'Rain animation is already running'
    return
  end

  -- Initialize namespace
  if not state.namespace then
    state.namespace = vim.api.nvim_create_namespace(config.namespace_name)
  end

  -- Create buffer and window
  local ok, result = pcall(function()
    state.buffer = create_rain_buffer()
    state.window = create_rain_window(state.buffer)
  end)

  if not ok then
    print('Failed to create rain animation: ' .. tostring(result))
    M.stop()
    return
  end

  state.is_running = true

  -- Create global timer for spawning raindrop batches (like the original)
  state.global_timer = vim.uv.new_timer()
  if not state.global_timer then
    print 'Failed to create global timer'
    M.stop()
    return
  end

  state.global_timer:start(
    config.initial_delay,
    config.spawn_interval,
    vim.schedule_wrap(function()
      if not state.is_running or not is_valid_buffer(state.buffer) then
        return
      end

      local dimensions = get_rain_dimensions()

      -- Create raindrops with staggered spawn times for more natural effect
      for i = 1, config.drop_count do
        local spawn_delay = math.random(0, config.spawn_interval - 50) -- Random delay within spawn interval
        local start_col = math.random(1, math.max(1, dimensions.width))
        local char = config.chars[math.random(1, #config.chars)]

        -- Create a timer for delayed spawning of this individual raindrop
        local spawn_timer = vim.uv.new_timer()
        if spawn_timer then
          table.insert(state.drop_timers, spawn_timer)
          spawn_timer:start(
            spawn_delay,
            0,
            vim.schedule_wrap(function()
              if state.is_running and is_valid_buffer(state.buffer) then
                create_single_raindrop(state.buffer, start_col, char)
              end
              -- Clean up the spawn timer
              cleanup_timer(spawn_timer)
              for j, timer in ipairs(state.drop_timers) do
                if timer == spawn_timer then
                  table.remove(state.drop_timers, j)
                  break
                end
              end
            end)
          )
        end
      end
    end)
  )
end

function M.stop()
  state.is_running = false

  -- Clean up all timers
  cleanup_all_timers()

  -- Clean up window and buffer
  cleanup_window_and_buffer()

  -- Clean up any orphaned rain buffers (fallback)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_valid_buffer(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match(config.namespace_name) then
        pcall(vim.api.nvim_buf_clear_namespace, buf, state.namespace, 0, -1)
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end
end

function M.toggle()
  if state.is_running then
    M.stop()
  else
    M.rain()
  end
end

function M.is_running()
  return state.is_running
end

-- Clean up on script reload
if state.is_running then
  M.stop()
end

M.setup = function(user_config)
  if user_config then
    for key, value in pairs(user_config) do
      if config[key] ~= nil then
        config[key] = value
      end
    end
  end

  -- Conditionally add '' character to config.chars based on diagonal chance
  table.insert(config.chars, config.diagonal_chance and '' or '|')

  -- Ensure namespace is created
  if not state.namespace then
    state.namespace = vim.api.nvim_create_namespace(config.namespace_name)
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
