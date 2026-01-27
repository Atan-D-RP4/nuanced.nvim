local M = {}

local uv = vim.uv
local api = vim.api
local fn = vim.fn
local notify = vim.notify
local fmt = string.format

-- CONFIG --------------------------------------------------------------
local audio_exts = {
  mp3 = true,
  wav = true,
  flac = true,
  m4a = true,
  ogg = true,
}

-- Playback state lives in vim.g so reloads retain it; also provide a local ref.
vim.g._music_playback = vim.g._music_playback
  or {
    process = nil,
    pipe = nil,
    gen = 0,
    auto_next = true,
    playing = false,
    paused = false,
    socket_path = nil,
  }
local state = vim.g._music_playback

-- HELPERS -------------------------------------------------------------
local function expand_home(path)
  return fn.expand(path)
end

local function get_music_dir()
  local x = os.getenv 'XDG_MUSIC_DIR'
  if x and x ~= '' then
    return expand_home(x)
  end
  return expand_home '~' .. '/Music'
end

-- Recursively scan `dir`, push matching files into `out` (array of absolute paths)
local function scan_audio(dir, out)
  local handle, err = uv.fs_scandir(dir)
  if not handle then
    -- silently ignore unreadable directories
    notify('scan_audio: ' .. (err or 'unknown') .. ' (' .. dir .. ')', vim.log.levels.DEBUG)
    return
  end

  while true do
    local name, typ = uv.fs_scandir_next(handle)
    if not name then
      break
    end

    local path = dir .. '/' .. name
    if typ == 'directory' then
      scan_audio(path, out)
    elseif typ == 'file' or typ == nil then
      -- some platforms return nil for file; guard by extension check
      local ext = name:match '^.+%.([^%.]+)$'
      if ext and audio_exts[ext:lower()] then
        table.insert(out, path)
      end
    end
  end
end

-- Build quickfix list from dir
function M.set_audio_quickfix(dir)
  dir = dir or get_music_dir()
  if dir == '' or not dir then
    notify('SetAudioQuickfix: no directory provided', vim.log.levels.WARN)
    return
  end

  local files = {}
  scan_audio(dir, files)

  if #files == 0 then
    notify('No audio files found in ' .. dir, vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, f in ipairs(files) do
    table.insert(items, { filename = f, lnum = 1, text = f })
  end

  fn.setqflist({}, 'r', { title = 'Audio Files', items = items })
  vim.cmd 'copen'
  notify(fmt('Loaded %d audio files from %s', #items, dir), vim.log.levels.INFO)
end

-- Clamp & move quickfix cursor by delta and return new row (or nil)
local function qf_move_delta(delta)
  local ok, win = pcall(api.nvim_get_current_win)
  if not ok or not win then
    return nil
  end
  local cur = api.nvim_win_get_cursor(win)
  local row = cur[1]
  local qfl = fn.getqflist()
  if not qfl or #qfl == 0 then
    return nil
  end
  local new_row = row + delta
  if new_row < 1 then
    new_row = 1
  end
  if new_row > #qfl then
    new_row = #qfl
  end
  api.nvim_win_set_cursor(win, { new_row, 0 })
  return new_row
end

-- Send command to MPV via IPC socket using vim.uv
local function send_mpv_command(cmd)
  if not state.socket_path or not state.playing then
    notify('No active playback', vim.log.levels.WARN)
    return false
  end

  -- Check if socket exists
  local stat = uv.fs_stat(state.socket_path)
  if not stat then
    notify('MPV socket not found', vim.log.levels.ERROR)
    return false
  end

  -- Construct JSON-RPC command for mpv
  local json_cmd = fmt('{ "command": [%s] }\n', cmd)

  -- Connect to Unix socket
  local pipe = uv.new_pipe(false)
  if not pipe then
    notify('Failed to create pipe', vim.log.levels.ERROR)
    return false
  end

  local success = false
  pipe:connect(state.socket_path, function(err)
    if err then
      notify('Failed to connect to MPV: ' .. err, vim.log.levels.ERROR)
      pipe:close()
      return
    end

    -- Write command
    pipe:write(json_cmd, function(write_err)
      if write_err then
        notify('Failed to send command: ' .. write_err, vim.log.levels.ERROR)
      else
        success = true
      end
      pipe:close()
    end)
  end)

  -- Wait briefly for the operation to complete
  vim.wait(100)
  return success
end

-- Public API: send raw command to MPV
function M.send_command(...)
  local args = { ... }
  local cmd_parts = {}

  for _, arg in ipairs(args) do
    if type(arg) == 'string' then
      table.insert(cmd_parts, fmt('"%s"', arg:gsub('"', '\\"')))
    elseif type(arg) == 'number' then
      table.insert(cmd_parts, tostring(arg))
    elseif type(arg) == 'boolean' then
      table.insert(cmd_parts, arg and 'true' or 'false')
    end
  end

  return send_mpv_command(table.concat(cmd_parts, ', '))
end

-- Toggle pause/play
function M.toggle_pause()
  if not state.playing then
    notify('No active playback', vim.log.levels.WARN)
    return
  end

  if send_mpv_command '"cycle", "pause"' then
    state.paused = not state.paused
    notify(state.paused and 'Paused' or 'Resumed', vim.log.levels.INFO)
  end
end

-- Seek forward/backward
function M.seek(seconds)
  if send_mpv_command(fmt('"seek", %d', seconds)) then
    notify(fmt('Seek %+ds', seconds), vim.log.levels.INFO)
  end
end

-- Adjust volume
function M.volume(delta)
  if send_mpv_command(fmt('"add", "volume", %d', delta)) then
    notify(fmt('Volume %+d', delta), vim.log.levels.INFO)
  end
end

-- Stop any current playback (increments generation to invalidate on_exit)
function M.stop_playback()
  -- increment generation so old on_exit callbacks do nothing
  state.gen = state.gen + 1

  if state.process then
    -- Send quit command first for clean exit
    if state.socket_path then
      local stat = uv.fs_stat(state.socket_path)
      if stat then
        pcall(send_mpv_command, '"quit"')
        vim.wait(100) -- Give mpv time to quit gracefully
      end
    end

    -- Then force kill the process
    if not state.process:is_closing() then
      state.process:kill(15) -- SIGTERM
    end
    state.process = nil
  end

  -- Cleanup socket file
  if state.socket_path then
    pcall(uv.fs_unlink, state.socket_path)
  end

  state.playing = false
  state.paused = false
  state.socket_path = nil

  notify('Playback stopped', vim.log.levels.INFO)
end

-- Internal: start playback for given audio_file (race-safe, bound-to-nvim)
local function start_playback(audio_file)
  if not audio_file or audio_file == '' then
    notify('No audio file to play', vim.log.levels.WARN)
    return
  end

  -- increment generation and capture for this job
  state.gen = state.gen + 1
  local my_gen = state.gen

  -- stop previous job (invalidate older callbacks)
  if state.process then
    M.stop_playback()
    vim.wait(100) -- Brief wait for cleanup
  end

  -- Create unique socket path for this instance
  local socket_path = fmt('/tmp/mpv-socket-%d-%d', uv.os_getpid(), my_gen)
  state.socket_path = socket_path

  -- Remove stale socket if exists
  pcall(uv.fs_unlink, socket_path)

  -- Spawn mpv process
  local handle, pid
  handle, pid = uv.spawn('mpv', {
    args = {
      '--no-video',
      '--really-quiet',
      '--no-terminal',
      '--input-ipc-server=' .. socket_path,
      audio_file,
    },
    stdio = { nil, nil, nil },
  }, function(exit_code, signal)
    vim.schedule(function()
      if state.gen ~= my_gen then
        -- stale callback; ignore
        return
      end

      -- Cleanup
      if state.socket_path then
        pcall(uv.fs_unlink, state.socket_path)
      end

      if handle and not handle:is_closing() then
        handle:close()
      end

      state.process = nil
      state.playing = false
      state.paused = false
      state.socket_path = nil

      if state.auto_next and exit_code == 0 then
        local row = qf_move_delta(1)
        if row and row > 0 then
          -- schedule next playback from main loop
          start_playback((fn.getqflist())[row].filename or (fn.getqflist())[row].text)
        end
      end
    end)
  end)

  if handle and pid then
    state.process = handle
    state.playing = true
    state.paused = false

    -- Wait a bit for socket to be created
    vim.wait(200, function()
      local stat = uv.fs_stat(socket_path)
      return stat ~= nil
    end)

    notify('Playing: ' .. fn.fnamemodify(audio_file, ':t'), vim.log.levels.INFO)
  else
    notify('Failed to start player', vim.log.levels.ERROR)
    state.socket_path = nil
  end
end

-- Play current quickfix entry (entry under cursor)
local function play_qf_audio()
  local qf_idx = fn.line '.'
  local qflist = fn.getqflist()
  if not qflist or not qflist[qf_idx] or (#qflist == 0) then
    notify('No quickfix item under cursor', vim.log.levels.WARN)
    return
  end

  local item = qflist[qf_idx]
  local audio_file = item.filename or item.text
  if not audio_file or audio_file == '' then
    notify('Quickfix entry has no filename/text', vim.log.levels.WARN)
    return
  end

  start_playback(audio_file)
end

-- Setup quickfix buffer-local mappings
local function ensure_qf_mappings(bufnr)
  -- run on next tick so internal qf mappings have been set
  vim.schedule(function()
    if not api.nvim_buf_is_valid(bufnr) then
      return
    end
    if vim.bo[bufnr].buftype ~= 'quickfix' then
      return
    end

    -- try to remove existing buffer-local mappings (safe via pcall)
    pcall(api.nvim_buf_del_keymap, bufnr, 'n', '<CR>')
    pcall(api.nvim_buf_del_keymap, bufnr, 'n', 'n')
    pcall(api.nvim_buf_del_keymap, bufnr, 'n', 'N')
    pcall(api.nvim_buf_del_keymap, bufnr, 'n', ']q')
    pcall(api.nvim_buf_del_keymap, bufnr, 'n', '[q')
    pcall(api.nvim_buf_del_keymap, bufnr, 'n', '<Space>')
    pcall(api.nvim_buf_del_keymap, bufnr, 'n', 'p')
    pcall(api.nvim_buf_del_keymap, bufnr, 'n', 's')

    local km_opts = { buffer = bufnr, silent = true, noremap = true, nowait = true }

    -- <CR> => play
    vim.keymap.set('n', '<CR>', function()
      play_qf_audio()
    end, km_opts)

    -- next / prev
    vim.keymap.set('n', 'n', function()
      qf_move_delta(1)
      play_qf_audio()
    end, km_opts)
    vim.keymap.set('n', 'N', function()
      qf_move_delta(-1)
      play_qf_audio()
    end, km_opts)

    -- ]q / [q
    vim.keymap.set('n', ']q', function()
      qf_move_delta(1)
      play_qf_audio()
    end, km_opts)
    vim.keymap.set('n', '[q', function()
      qf_move_delta(-1)
      play_qf_audio()
    end, km_opts)

    -- space => play
    vim.keymap.set('n', '<Space>', function()
      play_qf_audio()
    end, km_opts)

    -- p => pause/resume
    vim.keymap.set('n', 'p', function()
      M.toggle_pause()
    end, km_opts)

    -- s => stop
    vim.keymap.set('n', 's', function()
      M.stop_playback()
    end, km_opts)
  end)
end

-- AUTOCMDS / COMMANDS -----------------------------------------------
-- When entering a buffer, if it's quickfix, set buffer-local mappings.
api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'FileType' }, {
  callback = function(args)
    local bufnr = args.buf
    if not bufnr then
      return
    end
    if vim.bo[bufnr].buftype ~= 'quickfix' then
      return
    end
    ensure_qf_mappings(bufnr)
  end,
})

-- Cleanup on exit
api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    if state.playing then
      M.stop_playback()
    end
  end,
})

-- user commands
api.nvim_create_user_command('MusicQuickfix', function(opts)
  -- allow passing directory via :MusicQuickfix /path or default
  local dir = opts.args ~= '' and opts.args or nil
  M.set_audio_quickfix(dir)
end, { nargs = '?', complete = 'dir', desc = 'Populate quickfix with music files (default $XDG_MUSIC_DIR)' })

api.nvim_create_user_command('Music', function()
  if state.playing then
    M.toggle_pause()
  else
    notify('No active playback. Use <CR> in quickfix to start.', vim.log.levels.INFO)
  end
end, { desc = 'Toggle pause/resume for current music playback' })

api.nvim_create_user_command('MusicPlaybackToggle', function()
  if state.playing then
    M.stop_playback()
  else
    play_qf_audio()
  end
end, { desc = 'Toggle music playback (play/stop)' })

api.nvim_create_user_command('MusicToggleAutoNext', function()
  state.auto_next = not state.auto_next
  notify('Music auto-next: ' .. (state.auto_next and 'ON' or 'OFF'), vim.log.levels.INFO)
end, { desc = 'Toggle auto-advance after track finishes' })

api.nvim_create_user_command('MusicSeek', function(opts)
  local seconds = tonumber(opts.args)
  if not seconds then
    notify('Usage: :MusicSeek <seconds> (use negative to seek backward)', vim.log.levels.WARN)
    return
  end
  M.seek(seconds)
end, { nargs = 1, desc = 'Seek forward/backward by seconds' })

api.nvim_create_user_command('MusicVolume', function(opts)
  local delta = tonumber(opts.args)
  if not delta then
    notify('Usage: :MusicVolume <delta> (e.g., +10 or -10)', vim.log.levels.WARN)
    return
  end
  M.volume(delta)
end, { nargs = 1, desc = 'Adjust volume by delta' })

api.nvim_create_user_command('MusicCommand', function(opts)
  local args = vim.split(opts.args, '%s+')
  if #args == 0 then
    notify('Usage: :MusicCommand <command> [args...]', vim.log.levels.WARN)
    return
  end
  M.send_command(unpack(args))
end, { nargs = '+', desc = 'Send raw command to mpv' })

-- Expose a minimal public API
M.play = function()
  play_qf_audio()
end
M.stop = M.stop_playback
M.pause = M.toggle_pause
M.set_quickfix = M.set_audio_quickfix
M.state = state -- allow users to inspect/change state (e.g., auto_next)

return M
