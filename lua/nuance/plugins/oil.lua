return {
  {
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

    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      default_file_explorer = true,

      -- columns = {
      --   'icon',
      -- },

      buf_options = {
        buflisted = false,
        bufhidden = 'hide',
      },

      win_options = {
        wrap = false,
        signcolumn = 'yes:2',
        cursorcolumn = false,
        foldcolumn = '0',
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = 'nvic',
      },

      delete_to_trash = false,

      skip_confirm_for_simple_edits = false,

      prompt_save_on_select_new_entry = true,

      cleanup_delay_ms = 2000,
      lsp_file_methods = {

        enabled = true,

        timeout_ms = 1000,

        autosave_changes = false,
      },

      constrain_cursor = 'editable',

      watch_for_changes = false,

      keymaps = {
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
      },

      use_default_keymaps = true,
      view_options = {

        show_hidden = false,

        is_hidden_file = function(name, bufnr)
          return vim.startswith(name, '.')
        end,

        natural_order = true,

        is_always_hidden = function(name, bufnr)
          return false
        end,

        case_insensitive = false,
        sort = {
          { 'mtime', 'desc' },
          { 'type', 'asc' },
          { 'name', 'asc' },
        },
      },

      extra_scp_args = {},

      git = {
        add = function(path)
          return false
        end,
        mv = function(src_path, dest_path)
          return false
        end,
        rm = function(path)
          return false
        end,
      },

      float = {

        padding = 2,
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
      },

      preview = {

        max_width = 0.9,

        min_width = { 40, 0.4 },

        width = nil,

        max_height = 0.9,

        min_height = { 5, 0.1 },

        height = nil,
        border = 'rounded',
        win_options = {
          winblend = 0,
        },

        update_on_cursor_moved = true,
      },

      progress = {
        max_width = 0.9,
        min_width = { 40, 0.4 },
        width = nil,
        max_height = { 10, 0.9 },
        min_height = { 5, 0.1 },
        height = nil,
        border = 'rounded',
        minimized_border = 'none',
        win_options = {
          winblend = 0,
        },
      },

      ssh = {
        border = 'rounded',
      },

      keymaps_help = {
        border = 'rounded',
      },
    },
  },
}
