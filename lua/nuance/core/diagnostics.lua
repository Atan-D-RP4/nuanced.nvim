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

function M.setup()
  diagnostic_config {
    underline = true,
    severity_sort = true,
    float = {
      border = 'rounded',
    },
    jump = {
      on_jump = function(_, _)
        vim.diagnostic.open_float {
          focusable = false,
          close_events = { 'CursorMoved', 'InsertEnter', 'FocusLost' },
          border = 'rounded',
          source = 'if_many',
          prefix = ' ',
        }
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
      -- prefix = function(diagnostic, i, total)
      --   local symbols = vim.diagnostic.config().signs.text
      --   local symbol = symbols[diagnostic.severity] or '●'
      --   return symbol
      -- end,

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

    autocmd({ 'FileType', 'TextChanged', 'InsertLeave' }, {
      desc = 'Treesitter-based Diagnostics',
      pattern = '*',
      group = augroup 'treesitter-diagnostics',
      callback = vim.schedule_wrap(function()
        local bufnr = get_current_buf()

        -- Fast validation
        if not buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= '' then
          return
        end

        local ft = vim.bo[bufnr].filetype
        if vim.g.treesitter_diagnostics == false or excluded_filetypes[ft] then
          diagnostic_reset(M.namespace, bufnr)
          return
        end

        local ok, err = pcall(M.diagnostics, bufnr)
        if not ok then
          vim.notify(
            'Treesitter diagnostics error: ' .. tostring(err),
            vim.log.levels.ERROR,
            { title = 'Treesitter Diagnostics' }
          )
        end
      end),
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
          vim.notify(
            'Failed to run diagnostics: ' .. tostring(err),
            vim.log.levels.ERROR,
            { title = 'Treesitter Diagnostics' }
          )
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
  local current_config = diagnostic_config()

  if current_config.virtual_lines then
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

        local lnum = cursor[1] - 1
        local diagnostic_count = #diagnostic_get(ev.buf, { lnum = lnum })

        if diagnostic_count < 5 then
          diagnostic_config { virtual_text = og_virt_text, virtual_lines = false }
        else
          diagnostic_config { virtual_text = false }
          pcall(vim.diagnostic.open_float, {
            focusable = false,
            close_events = { 'CursorMoved', 'InsertEnter', 'FocusLost' },
            border = 'rounded',
            source = 'if_many',
            prefix = ' ',
          })
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

        local line = cursor[1] - 1
        local diagnostics = diagnostic_get(ev.buf, { lnum = line })
        local count = #diagnostics

        if count < 2 then
          diagnostic_config { virtual_text = og_virt_text }
        else
          diagnostic_config { virtual_text = false }
          pcall(vim.diagnostic.open_float, {
            focusable = false,
            close_events = { 'CursorMoved', 'InsertEnter', 'FocusLost' },
            border = 'rounded',
            source = 'if_many',
            prefix = ' ',
          })
        end
      end,
    })
  end
end

-- Cache the error query to avoid repeated parsing
local error_query
local function get_error_query()
  if not error_query then
    local ok, query = pcall(vim.treesitter.query.parse, 'query', '[(ERROR)(MISSING)] @a')
    if ok then
      error_query = query
    end
  end
  return error_query
end

---@param buf integer
function M.diagnostics(buf)
  -- Fast path: validate buffer and buffer type
  if not buf or not buf_is_valid(buf) or vim.bo[buf].buftype ~= '' then
    return
  end

  -- Check if treesitter is available
  local has_parser = pcall(vim.treesitter.get_parser, buf)
  if not has_parser then
    return
  end

  local query = get_error_query()
  if not query then
    return
  end

  local diagnostics = {}
  local parser = vim.treesitter.get_parser(buf, nil, { error = false })

  if not parser then
    return
  end

  -- Pre-allocate diagnostic template to reduce table allocations
  local diag_template = {
    source = 'Treesitter',
    bufnr = buf,
    namespace = M.namespace,
    severity = SEVERITY.ERROR,
  }

  local parse_ok = pcall(function()
    parser:parse(false, function(_, trees)
      if not trees then
        return
      end

      parser:for_each_tree(function(tree, ltree)
        if not tree or not tree:root() or not tree:root():has_error() then
          return
        end

        -- Cache language once per tree
        local lang = 'unknown'
        if ltree then
          local ok_lang, result = pcall(ltree.lang, ltree)
          if ok_lang then
            lang = result
          end
        end
        local code = lang .. '-syntax'

        for _, node in query:iter_captures(tree:root(), buf) do
          if not node then
            goto continue
          end

          local ok_range, lnum, col, end_lnum, end_col = pcall(node.range, node)
          if not ok_range then
            goto continue
          end

          -- Fast parent check for nested errors
          local parent = node:parent()
          if parent and parent:type() == 'ERROR' then
            local parent_ok, p_lnum, p_col, p_end_lnum, p_end_col = pcall(parent.range, parent)
            if parent_ok and p_lnum == lnum and p_col == col and p_end_lnum == end_lnum and p_end_col == end_col then
              goto continue
            end
          end

          -- Clamp ranges
          if end_lnum > lnum then
            end_lnum = lnum + 1
            end_col = 0
          end

          -- Build message
          local message
          local ok_missing, is_missing = pcall(node.missing, node)
          if ok_missing and is_missing then
            local ok_type, node_type = pcall(node.type, node)
            message = ok_type and string.format('missing `%s`', node_type) or 'missing element'
          else
            message = 'error'
          end

          -- Add context efficiently
          local previous = node:prev_sibling()
          if previous then
            local ok_prev_type, prev_type = pcall(previous.type, previous)
            if ok_prev_type and prev_type ~= 'ERROR' then
              local ok_named, is_named = pcall(previous.named, previous)
              local prev_name = (ok_named and is_named) and prev_type or string.format('`%s`', prev_type)
              message = message .. ' after ' .. prev_name
            end
          end

          if parent then
            local ok_parent_type, parent_type = pcall(parent.type, parent)
            if ok_parent_type and parent_type ~= 'ERROR' then
              local should_add = true
              if previous then
                local ok_prev_type, prev_type = pcall(previous.type, previous)
                should_add = not (ok_prev_type and prev_type == parent_type)
              end
              if should_add then
                message = message .. ' in ' .. parent_type
              end
            end
          end

          -- Create diagnostic using template (reduces allocations)
          diagnostics[#diagnostics + 1] = {
            source = diag_template.source,
            lnum = lnum,
            end_lnum = end_lnum,
            col = col,
            end_col = end_col,
            message = message,
            code = code,
            bufnr = diag_template.bufnr,
            namespace = diag_template.namespace,
            severity = diag_template.severity,
          }

          ::continue::
        end
      end)
    end)
  end)

  if parse_ok then
    pcall(diagnostic_set, M.namespace, buf, diagnostics)
  end
end

return M
