local M = {}

local augroup = require('nuance.core.utils').augroup
local autocmd = vim.api.nvim_create_autocmd
local api = vim.api

-- Cache frequently used functions
local buf_is_valid = api.nvim_buf_is_valid
local get_current_buf = api.nvim_get_current_buf
local win_get_cursor = api.nvim_win_get_cursor
local diagnostic_get = vim.diagnostic.get
local diagnostic_config = vim.diagnostic.config
local diagnostic_reset = vim.diagnostic.reset
local diagnostic_set = vim.diagnostic.set

-- Pre-allocate diagnostic severity for faster access
local SEVERITY = vim.diagnostic.severity

-- Initialize namespace once
M.namespace = api.nvim_create_namespace 'nuance-treesitter-diagnostics'

-- Cache diagnostic config values
local og_virt_text
local og_virt_line

-- Extract float config to avoid duplication
local DEFAULT_FLOAT_CONFIG = {
  focusable = false,
  close_events = { 'CursorMoved', 'InsertEnter', 'FocusLost' },
  border = 'rounded',
  source = 'if_many',
  prefix = ' ',
}

-- Debounce timer for diagnostics
-- Table to hold active timers per buffer
local diagnostics_timers = {}
local function schedule_diagnostics(bufnr, delay)
  delay = delay or 100

  -- Stop existing timer for buffer
  if diagnostics_timers[bufnr] then
    diagnostics_timers[bufnr]:stop()
    diagnostics_timers[bufnr]:close()
    diagnostics_timers[bufnr] = nil
  end

  -- Create a new uv timer
  local timer = vim.uv.new_timer()
  assert(timer, 'Failed to create uv timer for diagnostics')
  diagnostics_timers[bufnr] = timer

  timer:start(
    delay,
    0,
    vim.schedule_wrap(function()
      diagnostics_timers[bufnr] = nil

      -- Only run if buffer still valid
      if buf_is_valid(bufnr) then
        local ok, err = pcall(M.diagnostics, bufnr)
        if not ok then
          vim.notify('Treesitter diagnostics error: ' .. tostring(err), vim.log.levels.ERROR, { title = 'Treesitter Diagnostics' })
        end
      end

      -- cleanup
      timer:stop()
      timer:close()
    end)
  )
end

-- Optimized node operation helpers - reduced overhead
local function get_node_range(node)
  local ok, lnum, col, end_lnum, end_col = pcall(node.range, node)
  if ok then
    return lnum, col, end_lnum, end_col
  end
  return nil
end

local function get_node_type(node)
  local ok, node_type = pcall(node.type, node)
  if ok then
    return node_type
  end
  return nil
end

local function is_node_missing(node)
  local ok, is_missing = pcall(node.missing, node)
  return ok and is_missing
end

local function is_node_named(node)
  local ok, is_named = pcall(node.named, node)
  return ok and is_named
end

function M.setup()
  -- Cache diagnostic config values upfront
  local current_config = diagnostic_config()
  assert(current_config, 'Failed to get current diagnostic config')
  local has_virtual_lines = current_config.virtual_lines

  diagnostic_config {
    underline = true,
    severity_sort = true,
    float = {
      border = 'rounded',
    },
    jump = {
      on_jump = function(_, _)
        -- Use DEFAULT_FLOAT_CONFIG directly without tbl_extend
        vim.diagnostic.open_float(DEFAULT_FLOAT_CONFIG)
      end,
    },
    signs = vim.g.have_nerd_font and {
      text = {
        [SEVERITY.ERROR] = '󰅚 ',
        [SEVERITY.WARN] = '󰀪 ',
        [SEVERITY.INFO] = '󰋽 ',
        [SEVERITY.HINT] = '󰌶 ',
      },
    } or {},
    update_in_insert = false,
    virtual_lines = { current_line = true },

    virtual_text = {
      source = true,
      spacing = 2,
      ---@param diagnostic vim.Diagnostic
      format = function(diagnostic)
        return string.format('[%s] %s', diagnostic.code, diagnostic.message)
      end,
    },
  }

  if vim.g.treesitter_lint_available == true then
    -- Pre-compile excluded filetypes set for O(1) lookup
    local excluded_filetypes = {
      rust = true,
      markdown = true,
      text = true,
    }

    -- Helper to check if diagnostics should run
    local function should_run_diagnostics()
      local bufnr = get_current_buf()

      if not buf_is_valid(bufnr) then
        return false, nil
      end

      -- Cache buffer properties to avoid repeated API calls
      local buftype = vim.bo[bufnr].buftype
      local filetype = vim.bo[bufnr].filetype

      if vim.g.treesitter_diagnostics == false or excluded_filetypes[filetype] or buftype ~= '' then
        return false, bufnr
      end

      return true, bufnr
    end

    -- Use schedule_diagnostics with debounce instead of direct call
    -- FileType and InsertLeave are immediate (no reason for debounce)
    autocmd({ 'FileType', 'InsertLeave' }, {
      desc = 'Treesitter-based Diagnostics',
      pattern = '*',
      group = augroup 'treesitter-diagnostics',
      callback = function()
        local should_run, bufnr = should_run_diagnostics()
        if not should_run then
          if bufnr then
            diagnostic_reset(M.namespace, bufnr)
          end
          return
        end
        schedule_diagnostics(bufnr)
      end,
    })

    -- Use debounced diagnostics for TextChanged to avoid excessive updates
    autocmd('TextChanged', {
      desc = 'Treesitter-based Diagnostics (TextChanged)',
      pattern = '*',
      group = augroup 'treesitter-diagnostics',
      callback = function()
        local should_run, bufnr = should_run_diagnostics()
        if not should_run then
          if bufnr then
            diagnostic_reset(M.namespace, bufnr)
          end
          return
        end
        schedule_diagnostics(bufnr)
      end,
    })

    api.nvim_create_user_command('TSDiagnosticsToggle', function(_)
      vim.g.treesitter_diagnostics = not vim.g.treesitter_diagnostics
      local bufnr = get_current_buf()

      if not buf_is_valid(bufnr) then
        vim.notify('Invalid buffer', vim.log.levels.ERROR, { title = 'Treesitter Diagnostics' })
        return
      end

      diagnostic_reset(M.namespace, bufnr)

      if vim.g.treesitter_diagnostics then
        local ok, err = pcall(M.diagnostics, bufnr)
        if not ok then
          vim.notify('Failed to run diagnostics: ' .. tostring(err), vim.log.levels.ERROR, { title = 'Treesitter Diagnostics' })
          return
        end
      end

      local state = vim.g.treesitter_diagnostics and 'Enabled' or 'Disabled'
      vim.notify(
        state .. ' Treesitter diagnostics',
        vim.g.treesitter_diagnostics and vim.log.levels.INFO or vim.log.levels.WARN,
        { title = 'Treesitter Diagnostics', timeout = 5000, hide_from_history = false }
      )
    end, { nargs = 0, desc = 'Toggle Treesitter diagnostics' })
  end

  local diagnostic_float_or_virtlines_by_count = augroup 'diagnostic-float-or-virtlines-by-count'

  if has_virtual_lines then
    autocmd({ 'CursorHold' }, {
      desc = 'Toggle virtual lines based on diagnostics count',
      group = diagnostic_float_or_virtlines_by_count,
      callback = function(ev)
        if not buf_is_valid(ev.buf) then
          return
        end

        -- Lazy initialization
        if not og_virt_line then
          og_virt_line = diagnostic_config().virtual_lines
          if not (og_virt_line and og_virt_line.current_line) then
            return
          end
          og_virt_text = diagnostic_config().virtual_text
        end

        local ok, cursor = pcall(win_get_cursor, 0)
        if not ok then
          return
        end

        local lnum = cursor[1]
        assert(lnum, 'Failed to get cursor line')
        lnum = lnum - 1 -- Convert to 0-based
        local diagnostic_count = #diagnostic_get(ev.buf, { lnum = lnum })

        if diagnostic_count < 5 then
          diagnostic_config { virtual_text = og_virt_text, virtual_lines = false }
        else
          diagnostic_config { virtual_text = false }
          pcall(vim.diagnostic.open_float, DEFAULT_FLOAT_CONFIG)
        end
      end,
    })
  else
    autocmd('CursorHold', {
      desc = 'Toggle Diagnostic Float based on diagnostic count',
      group = diagnostic_float_or_virtlines_by_count,
      pattern = '*',
      callback = function(ev)
        if not buf_is_valid(ev.buf) or not vim.diagnostic.is_enabled() then
          return
        end

        -- Lazy initialization of original virtual_text config
        if not og_virt_text then
          og_virt_text = diagnostic_config().virtual_text
        end

        local ok, cursor = pcall(win_get_cursor, 0)
        if not ok then
          return
        end

        local line = cursor[1]
        assert(line, 'Failed to get cursor line')
        line = line - 1 -- Convert to 0-based
        local diagnostics = diagnostic_get(ev.buf, { lnum = line })
        local count = #diagnostics

        if count < 2 then
          diagnostic_config { virtual_text = og_virt_text }
        else
          diagnostic_config { virtual_text = false }
          pcall(vim.diagnostic.open_float, DEFAULT_FLOAT_CONFIG)
        end
      end,
    })
  end
end

-- Cache the error query to avoid repeated parsing
local error_query
---@return vim.treesitter.Query?
local function get_error_query()
  if not error_query then
    -- Query pattern for treesitter syntax errors and missing nodes
    local ok, qry = pcall(vim.treesitter.query.parse, 'query', '[(ERROR) (MISSING)] @error')
    if ok then
      error_query = qry
    else
      error_query = nil
    end
  end
  ---@diagnostic disable-next-line: return-type-mismatch
  return error_query
end

---@param buf integer
function M.diagnostics(buf)
  if not buf or not buf_is_valid(buf) or vim.bo[buf].buftype ~= '' then
    return
  end

  local parser = vim.treesitter.get_parser(buf, nil, { error = false })
  if not parser then
    return
  end

  local ok, trees = pcall(parser.parse, parser, true)
  if not ok or not trees then
    return
  end

  local diagnostics = {}

  for _, tree in ipairs(trees) do
    local root = tree:root()
    if not root or not root:has_error() then
      goto continue
    end

    local query = get_error_query()
    for _, node in query:iter_captures(root, buf) do
      if not node then
        goto continue
      end
      local lnum, col, end_lnum, end_col = get_node_range(node)
      if not lnum then
        goto continue
      end

      diagnostics[#diagnostics + 1] = {
        source = 'Treesitter',
        bufnr = buf,
        lnum = lnum,
        end_lnum = end_lnum,
        col = col,
        end_col = end_col,
        message = 'syntax error',
        severity = SEVERITY.ERROR,
      }
      ::continue::
    end
    ::continue::
  end

  pcall(diagnostic_set, M.namespace, buf, diagnostics)
end

return M
