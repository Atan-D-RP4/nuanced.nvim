-- TODO:
--
-- local custom = {
--   multi_open = function(prompt_bufnr)
--     local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
--     local multi = picker:get_multi_selection()
--
--     if vim.tbl_isempty(multi) then
--       require('telescope.actions').select_default(prompt_bufnr)
--       return
--     end
--
--     require('telescope.actions').close(prompt_bufnr)
--     for _, entry in pairs(multi) do
--       local filename = entry.filename or entry.value
--       local line = entry.lnum or 1
--       local col = entry.col or 1
--
--       vim.cmd(string.format('e +%d %s', line, filename))
--       vim.cmd(string.format('normal! %d|', col))
--     end
--   end,
--
--   buf_del = function(prompt_bufnr)
--     local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
--     local selection = picker:get_selection()
--
--     if vim.fn.buflisted(selection.bufnr) == 1 then
--       require('telescope.actions').delete_buffer(prompt_bufnr)
--     else
--       print 'Buffer is not open'
--     end
--   end,
--
--   grep_args = function()
--     if vim.fn.executable 'rg' == 1 then
--       return {
--         'rg',
--         '--color=never',
--         '--no-heading',
--         '--with-filename',
--         '--line-number',
--         '--column',
--         '--smart-case',
--       }
--     else
--       return {
--         'grep',
--         '--extended-regexp',
--         '--color=never',
--         '--with-filename',
--         '--line-number',
--         '-b', -- grep doesn't support a `--column` option :(
--         '--ignore-case',
--         '--recursive',
--         '--no-messages',
--         '--exclude-dir=*cache*',
--         '--exclude-dir=*.git',
--         '--exclude=.*',
--         '--binary-files=without-match',
--       }
--     end
--   end,
-- }

return {
  'ibhagwan/fzf-lua',
  branch = 'main',

  dependencies = {
    'nvim-lua/plenary.nvim',
  },

  cmd = 'FzfLua',

  keys = vim.tbl_map(function(c)
    -- Fzf command template
    local cmd = "<cmd>lua require('fzf-lua').%s()<CR>"

    -- Fzf command perfix
    local prefix = '<leader>f'

    return {
      prefix .. c.key,
      cmd:format(c.cmd),
      mode = c.mode,
      desc = c.desc,
    }
  end, {
    { mode = 'n', key = 'h', cmd = 'oldfiles', desc = '[F]ind [O]ld Files' },
    { mode = 'n', key = 'k', cmd = 'keymaps', desc = '[F]ind [K]eymaps' },
    { mode = 'n', key = 'f', cmd = 'files', desc = '[F]ind [F]iles' },
    { mode = 'n', key = 'b', cmd = 'builtin', desc = '[F]ind [B]uiltins' },
    { mode = 'v', key = 'v', cmd = 'grep_visual', desc = '[F]ind [V]isual' },
    { mode = 'n', key = 'g', cmd = 'live_grep_native', desc = '[F]ind by [G]rep' },
    { mode = 'n', key = 'd', cmd = 'lsp_document_diagnostics', desc = '[F]ind [D]iagnostics' },
    { mode = 'n', key = 'r', cmd = 'resume', desc = '[F]ind [R]esume' },
    { mode = 'n', key = 'o', cmd = 'oldfiles', desc = '[F]ind [O]ld Files' },
    { mode = 'n', key = 'e', cmd = 'buffers', desc = '[F]ind [B]uffers' },
    { mode = 'n', key = 'c', cmd = 'command_history', desc = '[F]ind [C]ommands' },
    { mode = 'n', key = 'n', cmd = 'files({ cwd = vim.fn.stdpath "config", follow = true },)', desc = '[F]ind [N]ear' },
  }),

  config = function()

    -- Use fzf-lua as the default ui
    vim.defer_fn(function()
      require('fzf-lua').register_ui_select()
    end, 100)

    require('fzf-lua').setup {
      'max_perf',
      keymaps = {
        builtin = {
          ["<C-p>"] = 'toggle-preview',
        },
        fzf = {
          ["<C-p>"] = 'toggle-preview',
        }
      },
      winopts = {
        win_height = 0.85,
        win_width = 0.80,
        win_row = 0.30,
        win_col = 0.50,
      },
    }
  end,
}
