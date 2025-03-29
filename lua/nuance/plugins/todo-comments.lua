-- Highlight todo, notes, etc in comments
local M = {
  'folke/todo-comments.nvim',
  lazy = true,
  event = { 'BufRead' },
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = { signs = false },
}

return M
-- vim: ts=2 sts=2 sw=2 et
