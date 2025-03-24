-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  -- Check if clipboard support is available
  if vim.fn.has 'clipboard' == 0 then
    return
  end

  -- Platform-specific clipboard configuration
  vim.opt.clipboard = 'unnamedplus,unnamed'
  local function paste()
    if os.getenv 'TERM_PROGRAM' == 'tmux' then
      return {
        'tmux',
        'save-buffer',
        '-',
      }
    end
    return {
      vim.fn.split(vim.fn.getreg '', '\n'),
      vim.fn.getregtype '',
    }
  end

  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy '+',
      ['*'] = require('vim.ui.clipboard.osc52').copy '*',
    },
    -- For security reasons, pasting is usually not supported by terminals for OSC52
    -- So we don't use clipboard.osc52 for pasting to avoid nvim hanging
    paste = {
      ['+'] = paste,
      ['*'] = paste,
    },
    cache_enabled = 1,
  }
end)

-- vim: ts=2 sts=2 sw=2 et
