local M = {}

local augroup = require('nuance.core.utils').augroup
local autocmd = vim.api.nvim_create_autocmd

function M.setup()
  vim.diagnostic.config {
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
        [vim.diagnostic.severity.ERROR] = '󰅚 ',
        [vim.diagnostic.severity.WARN] = '󰀪 ',
        [vim.diagnostic.severity.INFO] = '󰋽 ',
        [vim.diagnostic.severity.HINT] = '󰌶 ',
      },
    } or {},
    update_in_insert = false,
    virtual_lines = { current_line = true },

    virtual_text = {
      source = true,
      spacing = 2,
      ---@param diagnostic vim.Diagnostic
      format = function(diagnostic)
        local diagnostic_message = {
          [vim.diagnostic.severity.ERROR] = diagnostic.message,
          [vim.diagnostic.severity.WARN] = diagnostic.message,
          [vim.diagnostic.severity.INFO] = diagnostic.message,
          [vim.diagnostic.severity.HINT] = diagnostic.message,
        }
        return string.format('[%s] %s', diagnostic.code, diagnostic_message[diagnostic.severity])
      end,
    },
  }

  if vim.g.treesitter_lint_available == true then
    autocmd({ 'FileType', 'TextChanged', 'InsertLeave' }, {
      desc = 'Treesitter-based Diagnostics',
      pattern = '*',
      group = augroup 'treesitter-diagnostics',
      callback = vim.schedule_wrap(function()
        local bufnr = vim.api.nvim_get_current_buf()
        local excluded_filetypes = { 'rust', 'markdown', 'text' } -- Add filetypes to exclude here
        local ft = vim.bo[bufnr].filetype

        if vim.g.treesitter_diagnostics == false or vim.tbl_contains(excluded_filetypes, ft) then
          vim.diagnostic.reset(M.namespace, bufnr)
          return
        end
        M.diagnostics(bufnr)
      end),
    })

    vim.api.nvim_create_user_command('TSDiagnosticsToggle', function(_)
      -- Toggle the global flag
      vim.g.treesitter_diagnostics = not vim.g.treesitter_diagnostics

      local bufnr = vim.api.nvim_get_current_buf()

      -- Reset existing diagnostics
      vim.diagnostic.reset(M.namespace, bufnr)

      -- If diagnostics are now enabled, run diagnostics immediately
      if vim.g.treesitter_diagnostics then
        -- Force run the diagnostics function directly
        M.diagnostics(bufnr)
      end

      -- Notify the user about the current state
      local state = vim.g.treesitter_diagnostics and 'Enabled' or 'Disabled'
      vim.notify(
        state .. ' Treesitter diagnostics',
        vim.g.treesitter_diagnostics and vim.log.levels.INFO or vim.log.levels.WARN,
        { title = 'Treesitter Diagnostics', timeout = 5000, hide_from_history = false }
      )
    end, { nargs = 0, desc = 'Toggle Treesitter diagnostics' })
  end

  local diagnostic_float_or_virtlines_by_count = augroup 'diagnostic-float-or-virtlines-by-count'
  if vim.diagnostic.config().virtual_lines then
    local og_virt_text
    local og_virt_line
    autocmd({ 'CursorHold' }, {
      desc = 'Toggle virtual lines based on diagnostics count',
      group = diagnostic_float_or_virtlines_by_count,
      callback = function(ev)
        if og_virt_line == nil then
          og_virt_line = vim.diagnostic.config().virtual_lines
        end

        -- ignore if virtual_lines.current_line is disabled
        if not (og_virt_line and og_virt_line.current_line) then
          if og_virt_text then
            vim.diagnostic.config { virtual_text = og_virt_text }
            og_virt_text = nil
          end
          return
        end

        if og_virt_text == nil then
          og_virt_text = vim.diagnostic.config().virtual_text
        end

        local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

        local diagnostic_count = #vim.diagnostic.get(ev.buf, { lnum = lnum })
        if diagnostic_count < 5 then
          vim.diagnostic.config { virtual_text = og_virt_text }
          vim.diagnostic.config { virtual_lines = false }
        else
          vim.diagnostic.config { virtual_text = false }
          vim.diagnostic.open_float {
            focusable = false,
            close_events = { 'CursorMoved', 'InsertEnter', 'FocusLost' },
            border = 'rounded',
            source = 'if_many',
            prefix = ' ',
          }
        end
      end,
    })
  else
    autocmd('CursorHold', {
      desc = 'Toggle Diagnostic Float based on diagnostic count',
      group = diagnostic_float_or_virtlines_by_count,
      pattern = '*',
      callback = function(ev)
        if not vim.diagnostic.is_enabled() then
          return
        end
        local line = vim.api.nvim_win_get_cursor(0)[1] - 1
        local diagnostics = vim.diagnostic.get(ev.buf, { lnum = line })

        if #diagnostics < 2 then
          vim.diagnostic.config { virtual_text = true }
        else
          vim.diagnostic.config { virtual_text = false }
          vim.diagnostic.open_float {
            focusable = false,
            close_events = { 'CursorMoved', 'InsertEnter', 'FocusLost' },
            border = 'rounded',
            source = 'if_many',
            prefix = ' ',
          }
        end
      end,
    })
  end
end

-- https://www.reddit.com/r/neovim/comments/1ir069p/treesitter_diagnostics/
-- language-independent query for syntax errors and missing elements
---@param buf integer
function M.diagnostics(buf)
  -- don't diagnose strange stuff
  if vim.bo[buf].buftype ~= '' then
    return
  end

  M.namespace = vim.api.nvim_create_namespace 'nuance-treesitter-diagnostics'
  local error_query = vim.treesitter.query.parse('query', '[(ERROR)(MISSING)] @a')

  local diagnostics = {}
  local parser = vim.treesitter.get_parser(buf, nil, { error = false })
  if parser then
    parser:parse(false, function(_, trees)
      if not trees then
        return
      end
      parser:for_each_tree(function(tree, ltree)
        -- only process trees containing errors
        if tree:root():has_error() then
          for _, node in error_query:iter_captures(tree:root(), buf) do
            local lnum, col, end_lnum, end_col = node:range()

            -- collapse nested syntax errors that occur at the exact same position
            local parent = node:parent()
            if parent and parent:type() == 'ERROR' and parent:range() == node:range() then
              goto continue
            end

            -- clamp large syntax error ranges to just the line to reduce noise
            if end_lnum > lnum then
              end_lnum = lnum + 1
              end_col = 0
            end

            --- @type vim.Diagnostic
            local diagnostic = {
              source = 'Treesitter',
              lnum = lnum,
              end_lnum = end_lnum,
              col = col,
              end_col = end_col,
              message = '',
              code = string.format('%s-syntax', ltree:lang()),
              bufnr = buf,
              namespace = M.namespace,
              severity = vim.diagnostic.severity.ERROR,
            }
            if node:missing() then
              diagnostic.message = string.format('missing `%s`', node:type())
            else
              diagnostic.message = 'error'
            end

            -- add context to the error using sibling and parent nodes
            local previous = node:prev_sibling()
            if previous and previous:type() ~= 'ERROR' then
              local previous_type = previous:named() and previous:type() or string.format('`%s`', previous:type())
              diagnostic.message = diagnostic.message .. ' after ' .. previous_type
            end

            if parent and parent:type() ~= 'ERROR' and (previous == nil or previous:type() ~= parent:type()) then
              diagnostic.message = diagnostic.message .. ' in ' .. parent:type()
            end

            table.insert(diagnostics, diagnostic)
            ::continue::
          end
        end
      end)
    end)
    vim.diagnostic.set(M.namespace, buf, diagnostics)
  end
end

return M
