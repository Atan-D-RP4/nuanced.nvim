-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  -- Check if clipboard support is available
  if vim.fn.has('clipboard') == 0 then
    return
  end

  local os_name = vim.loop.os_uname().sysname

  -- Platform-specific clipboard configuration
  if os_name == 'Windows_NT' then
    -- Native Windows configuration
    vim.opt.clipboard = 'unnamedplus'
    vim.g.clipboard = {
      name = 'Windows Clipboard',
      copy = {
        ['+'] = 'clip.exe',
        ['*'] = 'clip.exe',
      },
      paste = {
        ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
        ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      },
      cache_enabled = 0,
    }
  elseif os.getenv("SSH_TTY") ~= nil then
    -- SSH session configuration (OSC 52)
    local function paste()
      return {
        vim.fn.split(vim.fn.getreg(""), "\n"),
        vim.fn.getregtype(""),
      }
    end

    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
        ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
      },
      -- For security reasons, pasting is usually not supported by terminals for OSC52
      -- So we don't use clipboard.osc52 for pasting to avoid nvim hanging
      paste = {
        ["+"] = paste,
        ["*"] = paste,
      },
    }
  elseif os.getenv("WSL_DISTRO_NAME") then
    -- WSL (Windows Subsystem for Linux) configuration
    vim.opt.clipboard = 'unnamedplus'
    vim.g.clipboard = {
      name = 'WslClipboard',
      copy = {
        ['+'] = 'clip.exe',
        ['*'] = 'clip.exe',
      },
      paste = {
        ['+'] = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
        ['*'] = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      },
      cache_enabled = 0,
    }
  else
    -- Default Linux configuration
    vim.opt.clipboard = 'unnamedplus,unnamed'
  end
end)
