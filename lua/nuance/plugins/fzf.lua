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
    { '<leader>fn', '<cmd>lua require("fzf-lua").files({ cwd = vim.fn.stdpath "config", follow = true })<CR>', desc = '[F]zf [N]ear', mode = 'n' },
    -- { '<leader>fe', '<cmd>lua require("fzf-lua").buffers()<CR>', desc = '[F]zf [B]uffers', mode = 'n' },
    -- { '<leader>fc', '<cmd>lua require("fzf-lua").command_history()<CR>', desc = '[F]zf [C]ommands', mode = 'n' },
    -- { '<leader>fd', '<cmd>lua require("fzf-lua").lsp_document_diagnostics()<CR>', desc = '[F]zf [D]iagnostics', mode = 'n' },
    { '<leader>fs', '<cmd>lua require("fzf-lua").lsp_document_symbols()<CR>', desc = '[F]zf [D]iagnostics', mode = 'n' },
  },

  config = function()
    -- Use fzf-lua as the default ui
    vim.defer_fn(function()
      require('fzf-lua').register_ui_select()
    end, 100)

    require('fzf-lua').setup {
      'max_pref',
      -- Toggle preview with `Ctrl-p`
      -- keymap = {
      --   fzf = {
      --     ['ctrl-q'] = "jump-accept",
      --   },
      -- },

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

-- local function get_hash()
--   -- The get_hash() is utilised to create an independent "store"
--   -- By default `fre --add` adds to global history, in order to restrict this to
--   -- current directory we can create a hash which will keep history separate.
--   -- With this in mind, we can also append git branch to make sorting based on
--   -- Current dir + git branch
--   local str = 'echo "dir:' .. vim.fn.getcwd()
--   if vim.b.gitsigns_head then
--     str = str .. ';git:' .. vim.b.gitsigns_head .. '"'
--   end
--   vim.print(str)
--   local hash = vim.fn.system(str .. " | md5sum | awk '{print $1}'")
--   return hash
-- end
--
-- local function fzf_mru(opts)
--   local fzf = require 'fzf-lua'
--   opts = fzf.config.normalize_opts(opts, fzf.config.globals.files)
--   local hash = get_hash()
--   opts.cmd = 'command cat <(fre --sorted --store_name ' .. hash .. ") <(fd -t f) | awk '!x[$0]++'" -- | the awk command is used to filter out duplicates.
--   opts.fzf_opts = vim.tbl_extend('force', opts.fzf_opts, {
--     ['--tiebreak'] = 'index' -- make sure that items towards top are from history
--   })
--   opts.actions = vim.tbl_extend('force', opts.actions or {}, {
--     ['ctrl-d'] = {
--       -- Ctrl-d to remove from history
--       function(sel)
--         if #sel < 1 then return end
--         vim.fn.system('fre --delete ' .. sel[1] .. ' --store_name ' .. hash)
--       end,
--       -- This will refresh the list
--       fzf.actions.resume,
--     },
--     -- TODO: Don't know why this didn't work
--     -- ["default"] = {
--     --   fn = function(selected)
--     --     if #selected < 2 then
--     --       return
--     --     end
--     --     print('exec:', selected[2])
--     --     vim.cmd('!fre --add ' .. selected[2])
--     --     fzf.actions.file_edit_or_qf(selected)
--     --   end,
--     --   exec_silent = true,
--     -- },
--   })
--
--   fzf.core.fzf_wrap(opts, opts.cmd, function(selected)
--     if not selected or #selected < 2 then return end
--     vim.fn.system('fre --add ' .. selected[2] .. ' --store_name ' .. hash)
--     fzf.actions.act(opts.actions, selected, opts)
--   end)()
-- end
--
-- vim.api.nvim_create_user_command('FzfMru', fzf_mru, {})
-- vim.keymap.set("n","<C-p>", fzf_mru, {desc="Open Files"})
