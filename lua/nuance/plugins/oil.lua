local M = {
  'stevearc/oil.nvim',
  version = '*',
  cmd = 'Oil',

  keys = { { '<leader>o', '<cmd>lua require("oil").toggle_float()<CR>', mode = 'n', desc = 'Open Oil Window' } },

  init = function()
    ---@diagnostic disable-next-line: param-type-mismatch
    if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
      require('lazy').load { plugins = { 'oil.nvim' } }
      vim.cmd 'bd' -- Close the initial buffer
      vim.cmd('Oil ' .. vim.fn.argv(0))
    end
  end,
}

---@module 'oil'
---@class oil.SetupOpts
M.opts = {
  default_file_explorer = true,
  use_default_keymaps = true,
  skip_confirm_for_simple_edits = true,
  delete_to_trash = false,
  prompt_save_on_select_new_entry = true,
  ssh = { border = 'rounded' },
  keymaps_help = { border = 'rounded' },
  constrain_cursor = 'editable',
  watch_for_changes = true,
  columns = { 'icon', 'size', 'modified' },
  cleanup_delay_ms = 2000,
  extra_scp_args = {},
}

M.opts.buf_options = {
  buflisted = false,
  bufhidden = 'hide',
}

M.opts.win_options = {
  wrap = false,
  signcolumn = 'yes:2',
  cursorcolumn = false,
  foldcolumn = '0',
  spell = false,
  list = false,
  conceallevel = 3,
  concealcursor = 'nvic',
}

M.opts.lsp_file_methods = {
  enabled = true,
  timeout_ms = 1000,
  autosave_changes = false,
}

M.opts.keymaps = {
  ['g?'] = 'actions.show_help',
  ['l'] = 'actions.select',
  ['<C-s>'] = { 'actions.select', opts = { vertical = true }, desc = 'Open the entry in a vertical split' },
  ['<C-h>'] = { 'actions.select', opts = { horizontal = true }, desc = 'Open the entry in a horizontal split' },
  ['<C-t>'] = { 'actions.select', opts = { tab = true }, desc = 'Open the entry in new tab' },
  ['<C-p>'] = 'actions.preview',
  ['q'] = 'actions.close',
  ['<C-l>'] = 'actions.refresh',
  ['<C-x>'] = '',
  ['-'] = 'actions.parent',
  ['_'] = 'actions.open_cwd',
  ['`'] = 'actions.cd',
  ['~'] = { 'actions.cd', opts = { scope = 'tab' }, desc = ':tcd to the current oil directory', mode = 'n' },
  ['gs'] = 'actions.change_sort',
  ['gx'] = 'actions.open_external',
  ['g.'] = 'actions.toggle_hidden',
  ['g\\'] = 'actions.toggle_trash',
  ['<Right>'] = 'actions.select',
}

M.opts.view_options = {
  show_hidden = false,
  natural_order = true,

  is_hidden_file = function(name, _) -- function(name, bufnr)
    return vim.startswith(name, '.')
  end,

  is_always_hidden = function(_, _) -- function(name, bufnr)
    return false
  end,

  case_insensitive = false,
  sort = {
    { 'mtime', 'desc' },
    { 'type', 'asc' },
    { 'name', 'asc' },
  },
}

M.opts.git = {
  add = function(path)
    return false
  end,
  mv = function(src_path, dest_path)
    return false
  end,
  rm = function(path)
    return false
  end,
}

M.opts.float = {
  padding = 5,
  max_width = 0,
  max_height = 0,
  border = 'rounded',

  win_options = {
    winblend = 0,
  },

  get_win_title = nil,
  preview_split = 'auto',

  override = function(conf)
    return conf
  end,
}

---@class M.opts
M.opts.preview = {
  max_width = 0.9,
  min_width = { 40, 0.4 },
  width = nil,
  max_height = 0.9,
  min_height = { 5, 0.1 },
  height = nil,
  border = 'rounded',
  update_on_cursor_moved = true,
  win_options = { winblend = 0 },
}

M.opts.progress = {
  max_width = 0.9,
  min_width = { 40, 0.4 },
  width = nil,
  max_height = { 10, 0.9 },
  min_height = { 5, 0.1 },
  height = nil,
  border = 'rounded',
  minimized_border = 'none',
  win_options = { winblend = 0 },
}

return M
