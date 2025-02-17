--@param file string
local session_files = function(file)
  if vim.fn.isdirectory(file) == 1 then
    return {}
  end
  local lines = {}
  local cwd, cwd_pat = '', '^cd%s*'
  local buf_pat = '^badd%s*%+%d+%s*'
  for line in io.lines(file) do
    if string.find(line, cwd_pat) then
      cwd = line:gsub('%p', '%%%1')
    end
    if string.find(line, buf_pat) then
      lines[#lines + 1] = line
    end
  end
  local buffers = {}
  for k, v in pairs(lines) do
    buffers[k] = v:gsub(buf_pat, ''):gsub(cwd:gsub('cd%s*', ''), ''):gsub('^/?%.?/', '')
  end
  local buffer_lines = table.concat(buffers, '\n')
  return buffer_lines
end

local session_pick = function()
  local items = {} ---@type snacks.picker.finder.Item[]
  for _, session in pairs(MiniSessions.detected) do
    table.insert(items, {
      text = session.name,
      name = session.name,
      preview = { text = session_files(session.path) },
      path = session.path,
      modify_time = os.date('%Y-%m-%d %H:%M:%S', session.modify_time),
      type = session.type,
    })
  end
  require('snacks.picker').pick {
    title = 'Sessions',
    items = items,
    preview = 'preview',
    format = function(item, _)
      local ret = {}
      ret[#ret + 1] = { item.name or '', '@string' }
      return ret
    end,
    actions = {
      delete = function(picker, item)
        MiniSessions['delete'](item.name)
        picker:ref()
      end,
    },
    win = {
      input = {
        keys = {
          ['<C-x>'] = 'delete',
        },
      },
    },
    confirm = function(_, item)
      if not item then
        return
      end

      vim.notify('Loaded session: ' .. item.name)
      MiniSessions.read(item.name, {})
    end,
  }
end

local mini_sessions = {
  'echasnovski/mini.sessions',
  event = 'VeryLazy',
  config = function()
    require('mini.sessions').setup {
      autoread = false,
      directory = vim.fn.stdpath 'data' .. '/sessions',
    }
  end,
  keys = {
    {
      '<leader>ap',
      function()
        session_pick()
      end,
      desc = '[S]essions [P]ick',
    },
    {
      '<leader>an',
      function()
        local name = vim.fn.input 'Session name: '
        if name == '' then
          print 'No session saved'
          return
        end
        require('mini.sessions').write(name)
      end,
      desc = '[S]essions [N]ew',
    },
    {
      '<leader>as',
      function()
        local ms = require 'mini.sessions'
        ms.write(ms.get_latest())
      end,
      desc = '[S]essions [S]ave/Update',
    },
  },
}

local possession = {
  'gennaro-tedesco/nvim-possession',
  enabled = require('nuance.disabled.fzf').enabled,

  dependencies = {
    'echasnovski/mini.sessions',
    'nvim-lua/plenary.nvim',
    'ibhagwan/fzf-lua',
  },

  keys = {
    { '<leader>al', '<cmd>lua require("nvim-possession").list()<CR>', desc = '[S]essions [L]ist' },
    { '<leader>an', '<cmd>lua require("nvim-possession").new()<CR>', desc = '[S]essions [N]ew' },
    { '<leader>as', '<cmd>lua require("nvim-possession").update()<CR>', desc = '[S]essions [S]ave/Update' },
    { '<leader>ad', '<cmd>lua require("nvim-possession").delete()<CR>', desc = '[S]essions [D]elete' },
  },
  config = function()
    require('mini.sessions').setup {
      autoread = false,
      directory = vim.fn.stdpath 'data' .. '/sessions',
    }
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
  end,
}

local M = mini_sessions

return M
