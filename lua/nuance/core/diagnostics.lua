-------------------------------------------------------------------------------
--- Treesitter Diagnostics Module for Neovim
-------------------------------------------------------------------------------
--- Provides treesitter-based syntax error detection and dynamic diagnostic
--- display toggling based on diagnostic count per line.
---
--- USAGE:
---   require('nuance.core.diagnostics').setup()
---
--- COMMANDS:
---   :TSDiagnosticsToggle    Toggle treesitter syntax diagnostics on/off
---
--- FEATURES:
---   1. Treesitter syntax error detection using ERROR/MISSING node queries
---   2. Dynamic virtual_text/virtual_lines switching based on diagnostic count
---   3. Debounced updates to avoid performance issues during rapid edits
---
-------------------------------------------------------------------------------
--- NEOVIM TREESITTER API PATTERNS DEMONSTRATED
-------------------------------------------------------------------------------
---
--- 1. GETTING A PARSER
---    Treesitter parsers are per-buffer and per-language:
---
---      local parser = vim.treesitter.get_parser(bufnr, lang, opts)
---      -- bufnr: Buffer number (0 = current)
---      -- lang:  Language name or nil (auto-detect from filetype)
---      -- opts:  { error = false } suppresses error on missing parser
---
---    Check if parser exists before using:
---      if not parser then return end
---
--- 2. PARSING AND GETTING TREES
---    Parser returns multiple trees (one per injected language):
---
---      local trees = parser:parse(true)  -- true = include injections
---      for _, tree in ipairs(trees) do
---        local root = tree:root()
---        -- Work with root node...
---      end
---
--- 3. CHECKING FOR ERRORS
---    Fast check before expensive query iteration:
---
---      if root:has_error() then
---        -- Contains ERROR or MISSING nodes
---      end
---
--- 4. QUERY API
---    Queries find nodes matching patterns:
---
---    Parse a query (do once, cache result):
---      local query = vim.treesitter.query.parse(lang, '[(ERROR) (MISSING)] @error')
---      -- Pattern: S-expression matching node types
---      -- @error: Capture name for matched nodes
---
---    Iterate captures:
---      for id, node, metadata in query:iter_captures(root, bufnr) do
---        local lnum, col, end_lnum, end_col = node:range()
---        -- Process node...
---      end
---
--- 5. NODE RANGE
---    Get node position (0-indexed):
---
---      local lnum, col, end_lnum, end_col = node:range()
---      -- lnum/col: Start position
---      -- end_lnum/end_col: End position (exclusive)
---
-------------------------------------------------------------------------------
--- VIM.UV TIMER PATTERNS (Debouncing)
-------------------------------------------------------------------------------
---
--- DEBOUNCE PATTERN:
---   Delays execution until input stops for a specified duration.
---   Used here to avoid running expensive diagnostics on every keystroke.
---
---   local timers = {}  -- Per-buffer timer tracking
---
---   function schedule_debounced(bufnr, delay, callback)
---     -- Cancel existing timer for this buffer
---     if timers[bufnr] then
---       timers[bufnr]:stop()
---       timers[bufnr]:close()
---       timers[bufnr] = nil
---     end
---
---     -- Create new timer
---     local timer = vim.uv.new_timer()
---     timers[bufnr] = timer
---
---     -- Start one-shot timer (repeat=0)
---     timer:start(delay, 0, vim.schedule_wrap(function()
---       timers[bufnr] = nil
---       callback()
---       timer:stop()
---       timer:close()
---     end))
---   end
---
--- CLEANUP ON BUFFER DELETE:
---   Always clean up timers when buffer is deleted to prevent leaks:
---
---   autocmd('BufDelete', {
---     callback = function(ev)
---       if timers[ev.buf] then
---         timers[ev.buf]:stop()
---         timers[ev.buf]:close()
---         timers[ev.buf] = nil
---       end
---     end
---   })
---
-------------------------------------------------------------------------------

local M = {}

local augroup = require('nuance.core.utils').augroup
local autocmd = vim.api.nvim_create_autocmd
local api = vim.api

local buf_is_valid = api.nvim_buf_is_valid
local get_current_buf = api.nvim_get_current_buf
local win_get_cursor = api.nvim_win_get_cursor
local diagnostic_get = vim.diagnostic.get
local diagnostic_config = vim.diagnostic.config
local diagnostic_reset = vim.diagnostic.reset
local diagnostic_set = vim.diagnostic.set

local SEVERITY = vim.diagnostic.severity

M.namespace = api.nvim_create_namespace 'nuance-treesitter-diagnostics'

local og_virt_text
local og_virt_line

local DEFAULT_FLOAT_CONFIG = {
  focusable = false,
  close_events = { 'CursorMoved', 'InsertEnter', 'FocusLost' },
  border = 'rounded',
  source = 'if_many',
  prefix = ' ',
}

-------------------------------------------------------------------------------
-- DEBOUNCE TIMER MANAGEMENT
-------------------------------------------------------------------------------

---@type table<integer, userdata> Per-buffer timer handles
local diagnostics_timers = {}

---Schedule diagnostics with debouncing.
---
---Cancels any pending timer for this buffer and schedules a new one.
---This prevents running expensive treesitter queries on every keystroke.
---
---@param bufnr integer Buffer number
---@param delay integer? Debounce delay in milliseconds (default: 100)
local function schedule_diagnostics(bufnr, delay)
  delay = delay or 100

  if diagnostics_timers[bufnr] then
    diagnostics_timers[bufnr]:stop()
    diagnostics_timers[bufnr]:close()
    diagnostics_timers[bufnr] = nil
  end

  local timer = vim.uv.new_timer()
  assert(timer, 'Failed to create uv timer for diagnostics')
  diagnostics_timers[bufnr] = timer

  timer:start(
    delay,
    0, -- repeat=0 means one-shot
    vim.schedule_wrap(function()
      diagnostics_timers[bufnr] = nil

      if buf_is_valid(bufnr) then
        local ok, err = pcall(M.diagnostics, bufnr)
        if not ok then
          vim.notify('Treesitter diagnostics error: ' .. tostring(err), vim.log.levels.ERROR, { title = 'Treesitter Diagnostics' })
        end
      end

      timer:stop()
      timer:close()
    end)
  )
end

-------------------------------------------------------------------------------
-- TREESITTER NODE HELPERS
-------------------------------------------------------------------------------

---Safely get node range with error handling.
---
---node:range() can throw if node is invalid (race condition with parser).
---
---@param node TSNode
---@return integer?, integer?, integer?, integer? lnum, col, end_lnum, end_col (0-indexed)
local function get_node_range(node)
  local ok, lnum, col, end_lnum, end_col = pcall(node.range, node)
  if ok then
    return lnum, col, end_lnum, end_col
  end
  return nil
end

-------------------------------------------------------------------------------
-- TREESITTER ERROR QUERY
-------------------------------------------------------------------------------

---@type vim.treesitter.Query?
local error_query

---Get or create the cached error query.
---
---Uses 'query' language to parse a pattern that matches ERROR and MISSING nodes.
---These are special node types treesitter creates for syntax errors.
---
---@return vim.treesitter.Query?
local function get_error_query()
  if not error_query then
    local ok, qry = pcall(vim.treesitter.query.parse, 'query', '[(ERROR) (MISSING)] @error')
    if ok then
      error_query = qry
    else
      if not M._query_error_notified then
        vim.notify('Failed to parse treesitter error query. Syntax diagnostics disabled.', vim.log.levels.WARN, { title = 'Treesitter Diagnostics' })
        M._query_error_notified = true
      end
      error_query = nil
    end
  end
  ---@diagnostic disable-next-line: return-type-mismatch
  return error_query
end

-------------------------------------------------------------------------------
-- SETUP
-------------------------------------------------------------------------------

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

    autocmd('BufDelete', {
      desc = 'Cleanup Treesitter diagnostics timers',
      pattern = '*',
      group = augroup 'treesitter-diagnostics',
      callback = function(ev)
        local bufnr = ev.buf
        if diagnostics_timers[bufnr] then
          if not diagnostics_timers[bufnr]:is_closing() then
            diagnostics_timers[bufnr]:stop()
            diagnostics_timers[bufnr]:close()
          end
          diagnostics_timers[bufnr] = nil
        end
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

  -- When there are many diagnostics on one line, virtual_text becomes unreadable.
  -- This switches to a float display when count exceeds threshold.
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
        lnum = lnum - 1 -- 1-indexed to 0-indexed
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
        line = line - 1 -- 1-indexed to 0-indexed
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

---Run treesitter diagnostics on a buffer.
---
---Parses the buffer with treesitter, queries for ERROR and MISSING nodes,
---and publishes them as vim.diagnostics.
---
---PERFORMANCE GUARDS:
--- - Skips files > 300KB (too expensive to parse)
--- - Skips special buffers (buftype ~= '')
--- - Uses cached query (parsed once)
---
---@param buf integer Buffer number
function M.diagnostics(buf)
  if not buf or not buf_is_valid(buf) or not api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= '' then
    return
  end

  local max_filesize = 307200 -- 300KB
  local filepath = api.nvim_buf_get_name(buf)
  if filepath ~= '' then
    local ok, stat = pcall(vim.uv.fs_stat, filepath)
    if ok and stat and stat.size > max_filesize then
      return
    end
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
    if not query then
      goto continue
    end

    for _, node in query:iter_captures(root, buf) do
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
