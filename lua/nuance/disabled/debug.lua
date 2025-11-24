-- debug.lua

-- Shows how to use the DAP plugin to debug your code.

-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

local mason_nvim_dap = {
  'jay-babu/mason-nvim-dap.nvim',
  dependencies = 'williamboman/mason.nvim',
  -- Makes a best effort to setup the various debuggers with
  -- reasonable debug configurations
  automatic_installation = true,

  -- You can provide additional configuration to the handlers,
  -- see mason-nvim-dap README for more information
  handlers = {},

  -- You'll need to check that you have the required things installed
  -- online, please don't ask me how to install them :)
  ensure_installed = {
    -- Update this to ensure that you have the debuggers for the langs you want
    'delve',
  },
}

local nvim_dap_ui = {
  'rcarriga/nvim-dap-ui',
  dependencies = { 'nvim-neotest/nvim-nio' },
  -- stylua: ignore
  keys = {
    { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
    { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
  },
  opts = {},
}

nvim_dap_ui.config = function()
  -- Dap UI setup

  require('dapui').setup {
    -- Set icons to characters that are more likely to work in every terminal.
    --    Feel free to remove or use ones that you like more! :)
    --    Don't feel like these are good choices.
    icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
    controls = {
      icons = {
        pause = '⏸',
        play = '▶',
        step_into = '⏎',
        step_over = '⏭',
        step_out = '⏮',
        step_back = 'b',
        run_last = '▶▶',
        terminate = '⏹',
        disconnect = '⏏',
      },
    },
  }

  -- Change breakpoint icons
  vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
  vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
  vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })

  local breakpoint_icons = vim.g.have_nerd_font
      and {
        Stopped = { '󰁕 ', 'DiagnosticWarn', 'DapStoppedLine' },
        Breakpoint = ' ',
        BreakpointCondition = ' ',
        BreakpointRejected = { ' ', 'DiagnosticError' },
        LogPoint = '.>',
      }
    or {
      Breakpoint = '●',
      BreakpointCondition = '⊜',
      BreakpointRejected = '⊘',
      LogPoint = '◆',
      Stopped = '⭔',
    }

  for name, sign in pairs(breakpoint_icons) do
    sign = type(sign) == 'table' and sign or { sign }
    vim.fn.sign_define('Dap' .. name, { text = sign[1], texthl = sign[2] or 'DiagnosticInfo', linehl = sign[3], numhl = sign[3] })
  end
end

local nvim_dap = {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',

  -- NOTE: And you can specify dependencies as well

  cmd = { 'DapToggleBreakpoint', 'DapClearBreakpoints' },
  keys = {
    { '<leader>dB', '<cmd>lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) <CR>', desc = 'Breakpoint Condition' },
    { '<leader>db', '<cmd>lua require("dap").toggle_breakpoint()<CR>', desc = 'Toggle Breakpoint' },
    { '<leader>dc', '<cmd>lua require("dap").continue()<CR>', desc = 'Run/Continue' },
    { '<leader>da', '<cmd>lua require("dap").continue({ before = get_args })<CR>', desc = 'Run with Args' },
    { '<leader>dC', '<cmd>lua require("dap").run_to_cursor()<CR>', desc = 'Run to Cursor' },
    { '<leader>dg', '<cmd>lua require("dap").goto_()<CR>', desc = 'Go to Line (No Execute)' },
    { '<leader>di', '<cmd>lua require("dap").step_into()<CR>', desc = 'Step Into' },
    { '<leader>dj', '<cmd>lua require("dap").down()<CR>', desc = 'Down' },
    { '<leader>dk', '<cmd>lua require("dap").up()<CR>', desc = 'Up' },
    { '<leader>dl', '<cmd>lua require("dap").run_last()<CR>', desc = 'Run Last' },
    { '<leader>do', '<cmd>lua require("dap").step_out()<CR>', desc = 'Step Out' },
    { '<leader>dO', '<cmd>lua require("dap").step_over()<CR>', desc = 'Step Over' },
    { '<leader>dP', '<cmd>lua require("dap").pause()<CR>', desc = 'Pause' },
    { '<leader>dr', '<cmd>lua require("dap").repl.toggle()<CR>', desc = 'Toggle REPL' },
    { '<leader>ds', '<cmd>lua require("dap").session()<CR>', desc = 'Session' },
    { '<leader>dt', '<cmd>lua require("dap").terminate()<CR>', desc = 'Terminate' },
    { '<leader>dw', '<cmd>lua require("dap.ui.widgets").hover()<CR>', desc = 'Widgets' },
  },
}

nvim_dap.dependencies = {
  -- Creates a beautiful debugger UI
  'rcarriga/nvim-dap-ui',
  -- Installs the debug adapters for you
  -- Add your own debuggers here
  'leoluz/nvim-dap-go',
}

nvim_dap.config = function()
  local dap = require 'dap'
  local dapui = require 'dapui'

  dap.listeners.after.event_initialized['dapui_config'] = dapui.open
  dap.listeners.before.event_terminated['dapui_config'] = dapui.close
  dap.listeners.before.event_exited['dapui_config'] = dapui.close

  -- Install golang specific config
  -- require('dap-go').setup {
  --   delve = {
  --     -- On Windows delve must be run attached or it crashes.
  --     -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
  --     detached = vim.fn.has 'win32' == 0,
  --   },
  -- }
end

return {
  nvim_dap,
  nvim_dap_ui,
  mason_nvim_dap,
}
