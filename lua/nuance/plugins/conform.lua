local M = {
  -- Autoformat
  'stevearc/conform.nvim',

  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  init = function()
    vim.api.nvim_create_user_command('ConformFormat', function(opts)
      require('conform').format { async = false, lsp_format = opts.fargs[1] }
    end, { nargs = 0, desc = 'Format buffer' })
  end,
}

M.keys = {
  {
    '<leader>cf',
    function()
      require('conform').format { async = false, lsp_format = 'fallback' }
    end,
    mode = '',
    desc = '[C]onform [F]ormat buffer',
  },
}

M.opts = {
  notify_on_error = false,

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
    lua = { 'stylua' },
    -- python = { 'ruff_format', 'black' },
    -- rust = { 'rustfmt' },
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
