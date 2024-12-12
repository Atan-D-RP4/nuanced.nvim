return {
  'ibhagwan/fzf-lua',
  branch = 'main',

  dependencies = {
    'nvim-lua/plenary.nvim',
  },

  cmd = 'FzfLua',
  keys = {
    { '<leader>gf', '<cmd>lua require("fzf-lua").git_commits()<CR>', desc = '[F]zf [G]it commit', mode = 'n' },
    { '<leader>fh', '<cmd>lua require("fzf-lua").help_tags()<CR>', desc = '[F]zf [H]elp tags', mode = 'n' },
    { '<leader>fk', '<cmd>lua require("fzf-lua").keymaps()<CR>', desc = '[F]zf [K]eymaps', mode = 'n' },
    { '<leader>fo', '<cmd>lua require("fzf-lua").oldfiles()<CR>', desc = '[F]zf [O]ld files', mode = 'n' },
    { '<leader>fv', '<cmd>lua require("fzf-lua").grep_visual()<CR>', desc = '[F]zf [V]isual', mode = 'v' },
    { '<leader>ff', '<cmd>lua require("fzf-lua").files()<CR>', desc = '[F]zf [Y] files', mode = 'n' },
    { '<leader>fg', '<cmd>lua require("fzf-lua").live_grep_native()<CR>', desc = '[F]zf [G]rep files', mode = 'n' },
    -- { '<leader>fd', '<cmd>lua require("fzf-lua").lsp_document_diagnostics()<CR>', desc = '[F]zf [D]iagnostics', mode = 'n' },
    -- { '<leader>fe', '<cmd>lua require("fzf-lua").buffers()<CR>', desc = '[F]zf [B]uffers', mode = 'n' },
    -- { '<leader>fc', '<cmd>lua require("fzf-lua").command_history()<CR>', desc = '[F]zf [C]ommands', mode = 'n' },
    { '<leader>fn', '<cmd>lua require("fzf-lua").files({ cwd = vim.fn.stdpath "config", follow = true })<CR>', desc = '[F]zf [N]ear', mode = 'n' },
  },

  config = function()
    -- Use fzf-lua as the default ui
    vim.defer_fn(function()
      require('fzf-lua').register_ui_select()
    end, 100)

    require('fzf-lua').setup {
      'max_pref',
      -- Toggle preview with `Ctrl-p`
      keymap = {
        fzf = {
          ['ctrl-p'] = 'toggle-preview',
        },
      },

      winopts = {
        preview = {
          hidden = 'hidden',
          default = 'bat_native',
        },
        win_height = 0.85,
        win_width = 0.80,
        win_row = 0.30,
        win_col = 0.50,
      },
    }
  end,
}
