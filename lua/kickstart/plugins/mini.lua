function SessionSave()
  local has_ms, mini_sessions = pcall(require, 'mini.sessions')
  if not has_ms then
    print 'Please install mini.nvim to use this feature'
    return
  end
  local session_name = vim.fn.input 'Session name: '
  if session_name == '' then
    print 'No session saved'
    return
  end

  mini_sessions.write(session_name)

  print('Session saved to: ' .. mini_sessions.get_latest())
end

-- Interatively select a session to load with telescope.nvim
function SessionLoad()
  local has_ms, mini_sessions = pcall(require, 'mini.sessions')
  if not has_ms then
    print 'Please install mini.nvim to use this feature'
    return
  end

  local has_ts, _ = pcall(require, 'telescope')
  if not has_ts then
    print 'Please install telescope.nvim to use this feature'
    return
  end

  -- Convert the detected sessions (key-value pairs) into a list of entries
  local get_sessions = function(detected_sessions)
    local sessions = {}
    for name, session_info in pairs(detected_sessions) do
      table.insert(sessions, {
        name = name,
        path = session_info.path,
        -- format the modify_time as a human-readable string
        modify_time = os.date('%Y-%m-%d %H:%M:%S', session_info.modify_time),
        type = session_info.type,
      })
    end
    return sessions
  end

  local make_finder = require('telescope.finders').new_table {
    results = get_sessions(mini_sessions.detected),
    entry_maker = function(entry)
      return {
        value = entry.path,
        display = string.format('[%s] %s (Modified: %s)', entry.type, entry.name, entry.modify_time),
        ordinal = entry.name,
      }
    end,
  }

  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Sessions',
      finder = make_finder,
      sorter = require('telescope.config').values.generic_sorter {},
      layout_strategy = 'vertical',
      layout_config = { width = 0.5, height = 0.5 },
      attach_mappings = function(_, map)
        map('i', '<CR>', function(prompt_bufnr)
          local entry = require('telescope.actions.state').get_selected_entry().value
          -- Usae/asd.vim -> Use/asd.vim
          entry = string.match(entry, '(.+%.vim)') -- Remove the trailing newline
          mini_sessions.read(entry) -- Load the selected session using its path
          require('telescope.actions').close(prompt_bufnr)
        end)

        map('i', '<C-d>', function(prompt_bufnr)
          local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
          local entry = require('telescope.actions.state').get_selected_entry().value
          if vim.fn.delete(entry, 'rf') == 0 then
            print('Deleted session: ' .. entry)
          end
          MiniSessions.setup() -- Re-detect sessions
          picker:refresh(
            require('telescope.finders').new_table {
              results = get_sessions(mini_sessions.detected),
              entry_maker = function(entry)
                return {
                  value = entry.path,
                  display = string.format('[%s] %s (Modified: %s)', entry.type, entry.name, entry.modify_time),
                  ordinal = entry.name,
                }
              end,
            },
            { reset_prompt = true }
          )
        end)
        return true
      end,
    })
    :find()
end

return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      require('mini.sessions').setup {
        autoread = true,
        autowrite = true,
        directory = vim.fn.stdpath 'data' .. '/sessions',
      }

      -- Command to save a session
      vim.keymap.set('n', '<leader>ss', SessionSave, { desc = '[S]ession [S]ave' })
      vim.keymap.set('n', '<leader>sl', SessionLoad, { desc = '[S]ession [L]oad' })

      require('mini.tabline').setup()

      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
