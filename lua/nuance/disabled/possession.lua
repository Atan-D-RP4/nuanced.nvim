M = {
  'gennaro-tedesco/nvim-possession',
  enabled = require('nuance.disabled.fzf').enabled,

  dependencies = {
    'nvim-lua/plenary.nvim',
    'ibhagwan/fzf-lua',
  },

  keys = {
    { '<leader>al', '<cmd>lua require("nvim-possession").list()<CR>', desc = '[S]essions [L]ist' },
    { '<leader>an', '<cmd>lua require("nvim-possession").new()<CR>', desc = '[S]essions [N]ew' },
    { '<leader>as', '<cmd>lua require("nvim-possession").update()<CR>', desc = '[S]essions [S]ave/Update' },
    { '<leader>ad', '<cmd>lua require("nvim-possession").delete()<CR>', desc = '[S]essions [D]elete' },
  },
}

M.opts = {
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

  post_hook = function()
    -- Clear any unnecessary buffers
    local bufs = vim.api.nvim_list_bufs()
    for _, bufnr in ipairs(bufs) do
      if not (vim.api.nvim_get_option_value('buflisted', { buf = bufnr }) == true and vim.api.nvim_buf_get_name(bufnr):len() > 0) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end
  end,
}

---@diagnostic disable-next-line: duplicate-set-field
M.config = function()
  -- Check if session dir exists and if not create it
  if vim.fn.isdirectory(require('nvim-possession.config').sessions.sessions_path) == 0 then
    vim.fn.mkdir(vim.fn.stdpath 'data' .. '/sessions', 'p')
  end

  local statusline = require 'mini.statusline'
  local default_section_filename = statusline.section_filename
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_filename = function(args)
    local session = require('nvim-possession').status()
    if session == nil then
      session = 'None'
    end
    return session .. ' ' .. default_section_filename(args)
  end
  require('nvim-possession').setup()
end

return M
