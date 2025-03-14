--- language-independent query for syntax errors and missing elements
M.namespace = vim.api.nvim_create_namespace 'nuance-treesitter-diagnostics'
local error_query = vim.treesitter.query.parse('query', '[(ERROR)(MISSING)] @a')

---@param event vim.api.keyset.create_autocmd.callback_args
function M.diagnostics(buf)
  -- don't diagnose strange stuff
  if vim.bo[buf].buftype ~= '' then
    return
  end

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
