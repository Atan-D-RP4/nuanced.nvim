local M = {
  -- Autoformat
  'stevearc/conform.nvim',
  cmd = { 'ConformInfo' },

  init = function()
    vim.api.nvim_create_user_command('ConformFormat', function(args)
      local range = nil
      if args.count ~= -1 then
        local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
        if end_line ~= nil then
          range = {
            start = { args.line1, 0 },
            ['end'] = { args.line2, end_line:len() },
          }
        end
      end

      require('conform').format({ async = true, lsp_format = 'fallback', range = range }, function()
        vim.notify('Buffer Formatted', vim.log.levels.INFO, { title = 'Conform' })
        -- vim.print(require('conform').get_formatter_config 'mdformat')
        -- vim.cmd 'exec "write"'
      end)
    end, { range = true, nargs = '?', desc = 'Format buffer with Conform' })
  end,
}

M.keys = {
  {
    '<leader>cf',
    '<cmd>ConformFormat<CR>',
    mode = { 'n', 'v' },
    desc = '[C]onform [F]ormat buffer',
  },
}

---@module "conform"
---@type conform.setupOpts
M.opts = {
  notify_on_error = true,

  -- format_on_save = function(bufnr)
  --   -- Disable "format_on_save lsp_fallback" for languages that don't
  --   -- have a well standardized coding style. You can add additional
  --   -- languages here or re-enable it for the disabled ones.
  --   local disable_filetypes = { c = true, cpp = true }
  --   local lsp_format_opt
  --   if disable_filetypes[vim.bo[bufnr].filetype] then
  --     lsp_format_opt = 'never'
  --   else
  --     lsp_format_opt = 'fallback'
  --   end
  --   return {
  --     timeout_ms = 500,
  --     lsp_format = lsp_format_opt,
  --   }
  -- end,

  formatters_by_ft = {
    yaml = { 'yamlfmt' },
    markdown = { 'mdformat' },
    lua = { 'stylua' },
    rust = { 'rustfmt' },
    sh = { 'shfmt' },
    -- Conform can also run multiple formatters sequentially
    -- python = { "isort", "black" },

    -- You can use 'stop_after_first' to run the first available formatter from the list
    -- javascript = { "prettierd", "prettier", stop_after_first = true },
  },

  formatters = {
    mdformat = {
      command = 'uv',
      args = { 'tool', 'run', 'mdformat', '--number', '-' },
      stdin = true,
    },
  },
}

return M
-- vim: ts=2 sts=2 sw=2 et
