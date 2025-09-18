local M = {
  -- Autoformat
  'stevearc/conform.nvim',
  cmd = { 'ConformInfo' },

  init = function()
    vim.api.nvim_create_user_command('ConformFormat', function(_)
      require('conform').format({ async = true, lsp_format = 'fallback' }, function()
        vim.notify('Buffer Formatted', vim.log.levels.INFO, { title = 'Conform' })
        vim.cmd 'exec "write"'
      end)
    end, { nargs = 0, desc = 'Format buffer' })
  end,
}

M.keys = {
  {
    '<leader>cf',
    function()
      require('conform').format({ async = true, lsp_format = 'fallback' }, function()
        vim.notify('Buffer Formatted', vim.log.levels.INFO, { title = 'Conform' })
        vim.cmd 'exec "write"'
      end)
    end,
    mode = '',
    desc = '[C]onform [F]ormat buffer',
  },
}

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
    markdown = { 'mdformat' },
    lua = { 'stylua' },
    python = { 'ruff_format' },
    rust = { 'rustfmt' },
    sh = { 'shfmt' },
    -- Conform can also run multiple formatters sequentially
    -- python = { "isort", "black" },
    --
    -- You can use 'stop_after_first' to run the first available formatter from the list
    -- javascript = { "prettierd", "prettier", stop_after_first = true },
  },
}

return M
-- vim: ts=2 sts=2 sw=2 et
