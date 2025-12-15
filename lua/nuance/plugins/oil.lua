local M = {
  'stevearc/oil.nvim',
  version = '*',
  cmd = 'Oil',

  keys = {
    { '<leader>oe', '<cmd>lua require("oil").open()<CR>', mode = 'n', desc = 'Open Oil Window' },
  },

  init = function()
    ---@diagnostic disable-next-line: param-type-mismatch
    if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
      require('lazy').load { plugins = { 'oil.nvim' } }
    end
  end,
}

---@module 'oil'
---@type oil.SetupOpts
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
  columns = { 'icon', 'size', 'mtime', 'modified' },
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
  number = false,
  relativenumber = false,
}

M.opts.lsp_file_methods = {
  enabled = true,
  timeout_ms = 1000,
  autosave_changes = 'unmodified',
}

M.opts.keymaps = {
  ['<leader>:'] = {
    'actions.open_cmdline',
    opts = { shorten_path = true },
    desc = 'Open the command line with the current directory as an argument',
  },
  ['<CR>'] = {},
  ['<C-l>'] = 'actions.refresh',
  ['<C-s>'] = { 'actions.select', opts = { vertical = true }, desc = 'Open the entry in a vertical split' },
  ['<C-h>'] = { 'actions.select', opts = { horizontal = true }, desc = 'Open the entry in a horizontal split' },
  ['<C-t>'] = { 'actions.select', opts = { tab = true }, desc = 'Open the entry in new tab' },
  ['<C-p>'] = 'actions.preview',
  ['<Right>'] = 'actions.select',
  ['l'] = { 'actions.select', mode = 'n' },
  ['Y'] = { 'actions.copy_entry_path', mode = 'n' },
  ['q'] = 'actions.close',
  ['='] = function() -- Save the current buffer
    require('oil').save({}, function(err)
      if err then
        vim.notify('Error syncing Oil buffer: ' .. tostring(err), vim.log.levels.ERROR)
        return
      end
      vim.tbl_map(function(bufnr)
        if vim.api.nvim_buf_is_valid(bufnr) and not vim.uv.fs_stat(vim.api.nvim_buf_get_name(bufnr)) then
          -- File no longer exists — close the buffer
          vim.api.nvim_buf_delete(bufnr, { force = true })
        end
      end, vim.tbl_keys(Bufline.tab_idx_map))
    end)
  end,
  ['-'] = 'actions.parent',
  ['_'] = 'actions.open_cwd',
  ['`'] = 'actions.cd',
  ['~'] = { 'actions.cd', opts = { scope = 'tab' }, desc = ':tcd to the current oil directory', mode = 'n' },
  ['gs'] = 'actions.change_sort',
  -- search and replace in the current directory
  ['g/'] = {
    callback = function()
      vim.print('Opening Grug Far Explorer Instance')
      local oil = require 'oil'
      local grug_far = require 'grug-far'

      -- get the current directory
      local prefills = { paths = oil.get_current_dir() }

      -- instance check
      if not grug_far.has_instance 'explorer' then
        grug_far.open {
          instanceName = 'explorer',
          prefills = prefills,
          staticTitle = 'Find and Replace from Explorer',
        }
      else
        grug_far.get_instance('explorer'):open()
        -- updating the prefills without clearing the search and other fields
        grug_far.get_instance('explorer'):update_input_values(prefills, false)
      end
    end,
    desc = 'oil: Search in directory',
  },
  ['gx'] = 'actions.open_external',
  ['g.'] = 'actions.toggle_hidden',
  ['g\\'] = 'actions.toggle_trash',
  ['g?'] = 'actions.show_help',
}

M.opts.view_options = {
  show_hidden = false,
  natural_order = true,

  is_hidden_file = function(name, _) -- function(name, bufnr)
    return vim.startswith(name, '.')
  end,

  is_always_hidden = function(name, _) -- function(name, bufnr)
    return name == '..' or name == '.'
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

-- M.opts.float = {
--   padding = 5,
--   max_width = 0,
--   max_height = 0,
--   border = 'rounded',

--   win_options = {
--     winblend = 0,
--   },

--   get_win_title = nil,
--   preview_split = 'auto',

--   override = function(conf)
--     return conf
--   end,
-- }

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
