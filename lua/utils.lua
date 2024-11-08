local utils = {}

function utils.map(mode, lhs, rhs, opts)
  local options = {}
  if opts then
    if type(opts) == 'string' then
      opts = { desc = opts }
    end
    options = vim.tbl_extend('force', options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

function utils.nmap(lhs, rhs, opts)
  utils.map('n', lhs, rhs, opts)
end

function utils.imap(lhs, rhs, opts)
  utils.map('i', lhs, rhs, opts)
end

function utils.tmap(lhs, rhs, opts)
  utils.map('t', lhs, rhs, opts)
end

function utils.vmap(lhs, rhs, opts)
  utils.map('v', lhs, rhs, opts)
end

function utils.sessionSave()
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
function utils.sessionLoad()
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

  local get_sessions = function()
    -- Convert the detected sessions (key-value pairs) into a list of entries
    local sessions = {}
    for name, session_info in pairs(MiniSessions.detected) do
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

  local state = require 'telescope.actions.state'
  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Sessions',
      finder = require('telescope.finders').new_table {
        results = get_sessions(),
        entry_maker = function(entry)
          return {
            value = entry.path,
            display = string.format('[%s] %s (Modified: %s)', entry.type, entry.name, entry.modify_time),
            ordinal = entry.name,
          }
        end,
      },
      sorter = require('telescope.config').values.generic_sorter {},
      layout_strategy = 'vertical',
      layout_config = { width = 0.5, height = 0.5 },
      attach_mappings = function(_, map)
        map('i', '<CR>', function()
          local entry = state.get_selected_entry().value
          entry = vim.fs.basename(entry)
          mini_sessions.read(entry) -- Load the selected session using its path
          vim.cmd [[bd #]]
          print('Loaded session: ' .. entry)
        end)

        map('i', '<C-d>', function(prompt_bufnr)
          local picker = state.get_current_picker(prompt_bufnr)
          local session = state.get_selected_entry().value
          MiniSessions.delete(session)
          picker:refresh(
            require('telescope.finders').new_table {
              results = get_sessions(),
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

return utils
