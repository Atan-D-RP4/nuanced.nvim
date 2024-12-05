-- local M = {}
--
-- function M.sessionSave()
--   require('mini.sessions').setup {
--     autoread = false,
--     directory = vim.fn.stdpath 'data' .. '/sessions',
--   }

--   local has_ms, mini_sessions = pcall(require, "mini.sessions")
--   if not has_ms then
--     print("Please install mini.nvim to use this feature")
--     return
--   end
--   local session_name = vim.fn.input("Session name: ")
--   if session_name == "" then
--     print("No session saved")
--     return
--   end
--
--   mini_sessions.write(session_name)
--
--   print("Session saved to: " .. mini_sessions.get_latest())
-- end
--
-- -- Interatively select a session to load with telescope.nvim
-- function M.sessionLoad()
--   local has_ms, mini_sessions = pcall(require, "mini.sessions")
--   if not has_ms then
--     print("Please install mini.nvim to use this feature")
--     return
--   end
--
--   local has_ts, _ = pcall(require, "telescope")
--   if not has_ts then
--     print("Please install telescope.nvim to use this feature")
--     return
--   end
--
--   local get_sessions = function()
--     -- Convert the detected sessions (key-value pairs) into a list of entries
--     local sessions = {}
--     for name, session_info in pairs(MiniSessions.detected) do
--       table.insert(sessions, {
--         name = name,
--         path = session_info.path,
--         -- format the modify_time as a human-readable string
--         modify_time = os.date("%Y-%m-%d %H:%M:%S", session_info.modify_time),
--         type = session_info.type,
--       })
--     end
--     return sessions
--   end
--
--   local state = require("telescope.actions.state")
--   require("telescope.pickers")
--     .new({}, {
--       prompt_title = "Sessions",
--       finder = require("telescope.finders").new_table({
--         results = get_sessions(),
--         entry_maker = function(entry)
--           return {
--             value = entry.path,
--             display = string.format("[%s] %s (Modified: %s)", entry.type, entry.name, entry.modify_time),
--             ordinal = entry.name,
--           }
--         end,
--       }),
--       sorter = require("telescope.config").values.generic_sorter({}),
--       layout_strategy = "vertical",
--       layout_config = { width = 0.5, height = 0.5 },
--       attach_mappings = function(_, map)
--         map("i", "<CR>", function()
--           local entry = state.get_selected_entry().value
--           entry = vim.fs.basename(entry)
--           mini_sessions.read(entry) -- Load the selected session using its path
--           vim.cmd([[bd #]])
--           print("Loaded session: " .. entry)
--         end)
--
--         map("i", "<C-d>", function(prompt_bufnr)
--           local picker = state.get_current_picker(prompt_bufnr)
--           local session = state.get_selected_entry().value
--           MiniSessions.delete(session)
--           picker:refresh(
--             require("telescope.finders").new_table({
--               results = get_sessions(),
--               entry_maker = function(entry)
--                 return {
--                   value = entry.path,
--                   display = string.format(
--                     "[%s] %s (Modified: %s)",
--                     entry.type,
--                     entry.name,
--                     entry.modify_time
--                   ),
--                   ordinal = entry.name,
--                 }
--               end,
--             }),
--             { reset_prompt = true }
--           )
--         end)
--         return true
--       end,
--     })
--     :find()
-- end
--
-- function M.init()
--   local utils = require 'core.utils'
--   local nmap = utils.nmap
--
--   nmap('<leader>ss', M.sessionSave, { desc = '[S]ession [S]ave' })
--   nmap('<leader>sl', M.sessionLoad, { desc = '[S]ession [L]oad' })
-- end

return {
  'gennaro-tedesco/nvim-possession',

  dependencies = {
    'nvim-lua/plenary.nvim',
    'ibhagwan/fzf-lua',
  },

  keys = {
    { '<leader>al', '<cmd>lua require("nvim-possession").list()<CR>', desc = '[L]ist' },
    { '<leader>an', '<cmd>lua require("nvim-possession").new()<CR>', desc = '[N]ew' },
    { '<leader>as', '<cmd>lua require("nvim-possession").update()<CR>', desc = '[S]ave/Update' },
    { '<leader>ad', '<cmd>lua require("nvim-possession").delete()<CR>', desc = '[D]elete' },
  },

  config = function()
    -- Check if session dir exists and if not create it
    if vim.fn.isdirectory(require('nvim-possession.config').sessions.sessions_path) == 0 then
      vim.fn.mkdir(vim.fn.stdpath 'data' .. '/sessions', 'p')
    end
    require('nvim-possession').setup {
      autoload = false,

      autoswitch = {
        enable = true,
      },

      fzf_winopts = {
        height = 0.4,
        width = 0.2,
        row = 0.5,
        col = 0.5,
      },
    }
  end,
}
