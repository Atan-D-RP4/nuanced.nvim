--[[
Health checks for the nuance Neovim configuration.
Run with :checkhealth nuance
--]]

local H = {}

--- Check Neovim version meets minimum requirements
H.check_version = function()
  local verstr = tostring(vim.version())
  if not vim.version.ge then
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
    return
  end

  if vim.version.ge(vim.version(), '0.10-dev') then
    vim.health.ok(string.format("Neovim version is: '%s'", verstr))
  else
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
  end
end

--- Check basic external tool requirements
H.check_external_reqs = function()
  for _, exe in ipairs { 'git', 'make', 'unzip', 'rg' } do
    local is_executable = vim.fn.executable(exe) == 1
    if is_executable then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.warn(string.format("Could not find executable: '%s'", exe))
    end
  end
end

--- Extract the primary executable from a server config
--- Handles both simple cmd arrays and complex deno-based commands
---@param server_config table
---@return string|nil executable, string|nil display_cmd
local function get_server_executable(server_config)
  local cmd = server_config.cmd
  if not cmd then
    return nil, nil
  end

  if type(cmd) == 'table' and #cmd > 0 then
    local primary_exe = cmd[1]
    local display = table.concat(cmd, ' ')
    return primary_exe, display
  elseif type(cmd) == 'string' then
    return cmd, cmd
  end

  return nil, nil
end

--- Check LSP server executables
H.check_lsp_servers = function()
  vim.health.start 'LSP Servers'

  local ok, lsp_configs = pcall(require, 'nuance.core.lsps')
  if not ok then
    vim.health.error('Failed to load nuance.core.lsps: ' .. tostring(lsp_configs))
    return
  end

  local enabled_count = 0
  local available_count = 0
  local missing = {}

  for name, config in pairs(lsp_configs) do
    if type(config) == 'table' then
      local enabled = config.enabled

      -- Handle boolean or expression-based enabled
      if enabled == true then
        enabled_count = enabled_count + 1
        local exe, display_cmd = get_server_executable(config)

        if exe then
          local is_available = vim.fn.executable(exe) == 1
          if is_available then
            available_count = available_count + 1
            vim.health.ok(string.format('%s: executable found (%s)', name, exe))
          else
            table.insert(missing, { name = name, exe = exe, cmd = display_cmd })
            vim.health.warn(string.format("%s: executable '%s' not found", name, exe))
          end
        else
          -- No cmd defined, relies on default or will be set dynamically
          available_count = available_count + 1
          vim.health.ok(string.format('%s: enabled (uses default cmd)', name))
        end
      elseif enabled == false then
        vim.health.info(string.format('%s: disabled', name))
      end
      -- enabled is an expression that evaluated to false at load time - skip
    end
  end

  vim.health.info(string.format('Summary: %d/%d enabled servers have executables available', available_count, enabled_count))

  if #missing > 0 then
    vim.health.info 'Missing executables can often be installed via Mason (:Mason) or your system package manager'
  end
end

--- Check if critical plugins are loaded
H.check_plugins = function()
  vim.health.start 'Plugins'

  -- Critical plugins that should be available
  local critical_plugins = {
    { name = 'lazy', module = 'lazy', desc = 'Plugin manager' },
    { name = 'snacks.nvim', module = 'snacks', desc = 'UI utilities' },
    { name = 'blink.cmp', module = 'blink.cmp', desc = 'Completion engine' },
    { name = 'conform.nvim', module = 'conform', desc = 'Formatter' },
    { name = 'nvim-treesitter', module = 'nvim-treesitter', desc = 'Syntax highlighting' },
    { name = 'oil.nvim', module = 'oil', desc = 'File explorer' },
    { name = 'gitsigns.nvim', module = 'gitsigns', desc = 'Git integration' },
    { name = 'mini.nvim', module = 'mini.ai', desc = 'Mini utilities' },
  }

  local loaded_count = 0
  for _, plugin in ipairs(critical_plugins) do
    local ok, _ = pcall(require, plugin.module)
    if ok then
      loaded_count = loaded_count + 1
      vim.health.ok(string.format('%s: loaded (%s)', plugin.name, plugin.desc))
    else
      vim.health.warn(string.format('%s: not loaded - %s', plugin.name, plugin.desc))
    end
  end

  vim.health.info(string.format('Summary: %d/%d critical plugins loaded', loaded_count, #critical_plugins))

  -- Check lazy.nvim plugin stats if available
  local lazy_ok, lazy = pcall(require, 'lazy')
  if lazy_ok then
    local stats = lazy.stats()
    vim.health.info(string.format('Lazy stats: %d plugins installed, %d loaded on startup', stats.count, stats.loaded))
  end
end

--- Check clipboard provider
H.check_clipboard = function()
  vim.health.start 'Clipboard'

  -- Check if clipboard is configured
  local clipboard = vim.g.clipboard
  if clipboard then
    vim.health.ok(string.format('Custom clipboard configured: %s', clipboard.name or 'unnamed'))
    return
  end

  -- Check for common clipboard providers
  local providers = {
    { exe = 'xclip', desc = 'X11 clipboard (xclip)' },
    { exe = 'xsel', desc = 'X11 clipboard (xsel)' },
    { exe = 'wl-copy', desc = 'Wayland clipboard (wl-clipboard)' },
    { exe = 'dms', desc = 'DankMaterialShell clipboard (dms-shell)' },
    { exe = 'pbcopy', desc = 'macOS clipboard' },
    { exe = 'win32yank.exe', desc = 'Windows clipboard' },
    { exe = 'lemonade', desc = 'Remote clipboard (lemonade)' },
    { exe = 'doitclient', desc = 'Remote clipboard (doit)' },
  }

  local found_provider = false
  for _, provider in ipairs(providers) do
    if vim.fn.executable(provider.exe) == 1 then
      vim.health.ok(string.format('Clipboard provider found: %s', provider.desc))
      found_provider = true
      break
    end
  end
  vim.print(found_provider)

  if not found_provider then
    -- Check if running in SSH without clipboard forwarding
    if vim.env.SSH_TTY then
      vim.health.warn 'Running in SSH session - clipboard may require forwarding or OSC 52 support'
    else
      vim.health.warn 'No clipboard provider found - install xclip, xsel, or wl-clipboard'
    end
  end

  -- Check OSC 52 support (terminal clipboard)
  if vim.env.TERM and (vim.env.TERM:match 'xterm' or vim.env.TERM:match 'tmux' or vim.env.TERM:match 'alacritty' or vim.env.TERM:match 'kitty') then
    vim.health.info 'Terminal may support OSC 52 clipboard - can work over SSH'
  end
end

--- Check Python environment (useful for Python LSPs)
H.check_python = function()
  vim.health.start 'Python Environment'

  -- Check for Python executables
  local python_exes = { 'python3', 'python' }
  local python_found = nil

  for _, exe in ipairs(python_exes) do
    if vim.fn.executable(exe) == 1 then
      python_found = exe
      local version = vim.fn.system(exe .. ' --version 2>&1'):gsub('\n', '')
      vim.health.ok(string.format('Python found: %s (%s)', exe, version))
      break
    end
  end

  if not python_found then
    vim.health.warn 'Python not found - Python LSPs may not work correctly'
    return
  end

  -- Check for uv (used by many Python LSPs in this config)
  if vim.fn.executable 'uv' == 1 then
    local uv_version = vim.fn.system('uv --version 2>&1'):gsub('\n', '')
    vim.health.ok(string.format('uv found: %s (used for Python tooling)', uv_version))
  else
    vim.health.info "uv not found - some Python LSPs use 'uvx' to run"
  end

  -- Check for virtual environment
  local venv = vim.env.VIRTUAL_ENV
  if venv then
    vim.health.ok(string.format('Virtual environment active: %s', venv))
  else
    vim.health.info 'No virtual environment active'
  end
end

return {
  check = function()
    vim.health.start 'nuance.nvim'

    vim.health.info [[NOTE: Not every warning is a 'must-fix' in `:checkhealth`

  Fix only warnings for plugins and languages you intend to use.
    Mason will give warnings for languages that are not installed.
    You do not need to install, unless you want to use those languages!]]

    local uv = vim.uv or vim.loop
    vim.health.info('System Information: ' .. vim.inspect(uv.os_uname()))

    H.check_version()
    H.check_external_reqs()
    H.check_lsp_servers()
    H.check_plugins()
    H.check_clipboard()
    H.check_python()
  end,
}
