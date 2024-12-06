return {
  {
    'moll/vim-bbye',
    config = function()
      require('core.utils').nmap('<leader>dd', ':Bdelete!<CR>', 'Delete Buffer')
      -- NOTE: Commented out since it breaks nvim-possession for now
      -- vim.api.nvim_create_autocmd('VimEnter', {
      --   desc = 'Delete Empty Buffer at startup',
      --   pattern = '*',
      --   callback = function()
      --     if vim.api.nvim_buf_get_name(0) == '' then
      --       vim.cmd 'Bdelete!'
      --     end
      --   end,
      -- })
    end,
  },

  {
    -- Buffer-Switcher
    'leath-dub/snipe.nvim',
    keys = vim.list_extend(
      {
        {
          '<leader>ee',
          function()
            require('snipe').open_buffer_menu()
          end,
          desc = 'Open Snipe buffer menu',
        },
      },
      vim.tbl_map(function(i)
        return {
          string.format('<leader>e%d', i),
          function()
            local Snipe = require 'snipe'
            local cmd = Snipe.config.sort == 'last' and 'ls t' or 'ls'
            local items = require('snipe.buffer').get_buffers(cmd)

            if Snipe.config.ui.text_align == 'file-first' then
              items = Snipe.file_first_format(items)
            end

            if i > #items or i == 0 then
              vim.notify('Buffer index out of range', vim.log.levels.ERROR)
              return
            end

            -- Jump to the nth buffer
            Snipe.global_menu:close()
            Snipe.global_menu.opened_from_wid = Snipe.global_menu:open_over()
            vim.api.nvim_set_current_win(Snipe.global_menu.opened_from_wid)
            vim.api.nvim_set_current_buf(items[i].id)
          end,
          desc = string.format('Jump to buffer %d', i),
        }
      end, { 1, 2, 3, 4, 5, 6, 7, 8, 9 })
    ),
    opts = {
      hints = {
        dictionary = '1234567890',
      },
    },
  },

  {
    -- Undotree
    'mbbill/undotree',
    cmd = 'UndotreeToggle',
    keys = {
      {
        '<leader>u',
        '<cmd>UndotreeToggle<CR>',
        desc = 'Toggle undotree',
      },
    },
  },

  -- {
  --   -- find/replace across multiple files
  --   'nvim-pack/nvim-spectre',
  --   keys = {
  --     { 'g/', '<cmd>Spectre<cr>', mode = { 'n' } },
  --   },
  --   config = function()
  --     require('spectre').setup { is_block_ui_break = true }
  --   end,
  -- }
}
