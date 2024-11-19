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
  event = 'VeryLazy',
  branch = 'main',

  dependencies = {
    'nvim-lua/plenary.nvim',
  },

  config = function()
    require('fzf-lua').setup {
      'telescope',
      -- Map tab to add selection
    }

    -- Use fzf-lua as the default ui
    vim.defer_fn(function()
      require('fzf-lua').register_ui_select()
    end, 100)

    -- Fzf command template
    local cmd = "<cmd>lua require('fzf-lua').%s<CR>"

    -- Fzf command perfix
    local prefix = '<leader>f'

    local nmap = require('utils').nmap

    nmap(prefix .. 'h', cmd:format 'help_tags()', { desc = '[F]ind [H]elp' })
    nmap(prefix .. 'k', cmd:format 'keymaps()', { desc = '[F]ind [K]eymaps' })
    nmap(prefix .. 'f', cmd:format 'files()', { desc = '[F]ind [F]iles' })
    nmap(prefix .. 'B', cmd:format 'builtin()', { desc = '[F]ind [B]uiltins' })
    nmap(prefix .. 'v', cmd:format 'grep_visual()', { desc = '[F]ind [V]isual' })
    nmap(prefix .. 'g', cmd:format 'live_grep()', { desc = '[F]ind by [G]rep' })
    nmap(prefix .. 'd', cmd:format 'lsp_document_diagnostics()', { desc = '[F]ind [D]iagnostics' })
    nmap(prefix .. 'r', cmd:format 'resume()', { desc = '[F]ind [R]esume' })
    nmap(prefix .. 'o', cmd:format 'oldfiles()', { desc = '[F]ind [O]ld Files' })
    nmap(prefix .. 'b', cmd:format 'buffers()', { desc = '[F]ind [B]uffers' })
    nmap(prefix .. 'c', cmd:format 'command_history()', { desc = '[F]ind [C]ommands' })

    nmap(prefix .. 'n', cmd:format 'files({ cwd = vim.fn.stdpath "config", follow = true })', { desc = '[F]ind [N]ear' })
  end,
}
