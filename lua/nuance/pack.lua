-- lua/nuance/pack.lua
-- Thin wrapper over vim.pack + lz.n for lazy.nvim-like experience

local M = {}

---@class PackSpec
---@field [1] string Plugin source (e.g., 'folke/tokyonight.nvim')
---@field name? string Override plugin name
---@field main? string Override module name for require() and setup()
---@field version? string|table Semver range or vim.version.range()
---@field branch? string Git branch name
---@field tag? string Git tag
---@field commit? string Git commit hash
---@field enabled? boolean|fun():boolean Whether plugin is registered (default: true)
---@field cond? boolean|fun():boolean Whether plugin auto-loads on triggers (default: true)
---@field dependencies? (string|PackSpec)[] Dependencies to load first
---@field init? fun() Run before plugin loads (runs even if plugin is lazy)
---@field opts? table Options passed to setup()
---@field config? fun(opts:table)|boolean Configuration function (true = auto-setup)
---@field build? string|fun(path:string) Build command after install/update
---@field event? string|string[] Lazy load on event(s)
---@field cmd? string|string[] Lazy load on command(s)
---@field ft? string|string[] Lazy load on filetype(s)
---@field keys? (string|table)[] Lazy load on keymap(s)
---@field colorscheme? string|string[] Lazy load on colorscheme
---@field priority? number Load priority (higher = earlier, default: 50)
---@field lazy? boolean Force lazy loading (default: auto-detected)
---@field dir? string Local plugin directory (skips git clone, creates symlink)
---@field import? string Module path to import additional specs from

-- Internal state
local plugins = {}
local build_hooks = {}
local loaded_plugins = {} -- Track which plugins have been loaded and what triggered them
-- Format: loaded_plugins[name] = "event:UIEnter" | "cmd:Foo" | "key:<leader>x" | "ft:lua" | "colorscheme" | "startup" | "manual" | "dependency"
local force_load = {} -- Track plugins being force-loaded via :PackLoad (to bypass cond)
local load_times = {} -- Track plugin load times in ms (for :PackProfile)
local local_plugins = {} -- Track local plugins (dir field) that skip vim.pack operations
local current_trigger = nil -- Track what's currently triggering a plugin load (set by custom handlers)

--- Expand import specs by requiring all modules in a directory
---@param specs (string|PackSpec)[]
---@return (string|PackSpec)[]
local function expand_imports(specs)
  local expanded = {}

  for _, spec in ipairs(specs) do
    if type(spec) == 'table' and spec.import then
      -- Convert module path to file path pattern
      local mod_path = spec.import:gsub('%.', '/')
      local config_path = vim.fn.stdpath 'config'
      local pattern = config_path .. '/lua/' .. mod_path .. '/*.lua'

      for _, file in ipairs(vim.fn.glob(pattern, false, true)) do
        local mod_name = spec.import .. '.' .. vim.fn.fnamemodify(file, ':t:r')
        local ok, mod = pcall(require, mod_name)
        if ok and type(mod) == 'table' then
          -- Handle both single specs and arrays of specs
          if type(mod[1]) == 'string' then
            -- Single spec: { 'author/plugin', ... }
            table.insert(expanded, mod)
          elseif type(mod[1]) == 'table' then
            -- Array of specs: { { 'author/plugin1' }, { 'author/plugin2' } }
            vim.list_extend(expanded, mod)
          end
        end
      end
    else
      table.insert(expanded, spec)
    end
  end

  return expanded
end

-- Utility functions
local function to_array(val)
  if val == nil then
    return {}
  end
  if type(val) == 'table' and val[1] then
    return val
  end
  return { val }
end

--- Normalize a name for comparison (like lazy.nvim's normname)
local function normname(name)
  return name:lower():gsub('^n?vim%-', ''):gsub('%.n?vim$', ''):gsub('[%.%-]lua', ''):gsub('[^a-z]+', '')
end

--- Get the plugin name from source URL (without suffix stripping)
local function get_name(src)
  local name = src:match '[^/]+$':gsub('%.git$', '')
  -- Remove trailing slash if present
  return name:gsub('/$', '')
end

--- Find the main module for a plugin by scanning its lua directory (like lazy.nvim)
---@param plugin_name string
---@param spec_main? string
---@return string?
local function get_main(plugin_name, spec_main)
  -- If main is explicitly specified, use it
  if spec_main then
    return spec_main
  end

  -- Special case for mini.nvim submodules
  if plugin_name ~= 'mini.nvim' and plugin_name:match '^mini%..*$' then
    return plugin_name
  end

  -- Find the plugin directory
  local pack_dir = vim.fn.stdpath 'data' .. '/site/pack/core/opt/' .. plugin_name
  local lua_dir = pack_dir .. '/lua'

  if vim.fn.isdirectory(lua_dir) == 0 then
    return nil
  end

  -- Scan lua directory for modules
  local norm_target = normname(plugin_name)
  local mods = {}

  for _, entry in ipairs(vim.fn.readdir(lua_dir) or {}) do
    local mod_path = lua_dir .. '/' .. entry
    local modname = nil

    if vim.fn.isdirectory(mod_path) == 1 then
      -- Directory - check for init.lua
      if vim.fn.filereadable(mod_path .. '/init.lua') == 1 then
        modname = entry
      end
    elseif entry:match '%.lua$' then
      -- Lua file
      modname = entry:gsub('%.lua$', '')
    end

    if modname then
      table.insert(mods, modname)
      -- Exact normalized match - use immediately
      if normname(modname) == norm_target then
        return modname
      end
    end
  end

  -- If only one module found, use it
  if #mods == 1 then
    return mods[1]
  end

  return nil
end

local function to_url(src)
  -- Convert GitHub shorthand to full URL (vim.pack requires full URLs)
  if src:match '^https?://' or src:match '^git@' then
    return src
  end
  return 'https://github.com/' .. src
end

--- Build vim.pack version spec from PackSpec
---@param spec PackSpec
---@return string|table|nil version for vim.pack
local function build_version_spec(spec)
  if spec.version then
    if type(spec.version) == 'string' and spec.version:match '[%*%^~>=<]' then
      return vim.version.range(spec.version)
    end
    return spec.version
  end
  return spec.branch or spec.tag or spec.commit
end

--- Detect what triggered a plugin load
---@param plugin_name string
---@return string
local function get_trigger(plugin_name)
  -- Use current_trigger if set (by our custom handlers or manual tracking)
  if current_trigger then
    local trigger = current_trigger
    current_trigger = nil -- Clear after use
    return trigger
  end

  -- Check if it was a manual load via :PackLoad
  if force_load[plugin_name] then
    return 'manual'
  end

  -- Fallback: guess from spec (less accurate, but better than nothing)
  local spec = plugins[plugin_name]
  if not spec then
    return 'unknown'
  end

  -- Check triggers in order of specificity
  if spec.colorscheme then
    return 'colorscheme'
  end
  if spec.ft then
    local ft = type(spec.ft) == 'table' and spec.ft[1] or spec.ft
    return 'ft:' .. ft
  end
  if spec.cmd then
    local cmd = type(spec.cmd) == 'table' and spec.cmd[1] or spec.cmd
    return 'cmd:' .. cmd
  end
  if spec.keys then
    local key = type(spec.keys) == 'table' and (type(spec.keys[1]) == 'table' and spec.keys[1][1] or spec.keys[1]) or spec.keys
    return 'key:' .. tostring(key)
  end
  if spec.event then
    local ev = type(spec.event) == 'table' and spec.event[1] or spec.event
    ev = type(ev) == 'table' and ev.event or ev
    return 'event:' .. tostring(ev)
  end
  if spec.lazy == false or spec.priority then
    return 'startup'
  end
  return 'dependency'
end

--- Convert our spec to lz.n spec format
---@param spec PackSpec
---@return table lz.n spec
local function to_lzn_spec(spec)
  local name = spec.name or get_name(spec[1])
  local short_name = get_name(spec[1])

  local lzn = { name }

  -- Copy trigger fields directly (lz.n handles these)
  if spec.event then
    lzn.event = spec.event
  end
  if spec.cmd then
    lzn.cmd = spec.cmd
  end
  if spec.ft then
    lzn.ft = spec.ft
  end
  if spec.keys then
    lzn.keys = spec.keys
  end
  if spec.colorscheme then
    lzn.colorscheme = spec.colorscheme
  end
  if spec.enabled ~= nil then
    lzn.enabled = spec.enabled
  end
  if spec.priority then
    lzn.priority = spec.priority
  end
  if spec.lazy ~= nil then
    lzn.lazy = spec.lazy
  end

  -- cond: conditional loading (plugin registered but may skip auto-load)
  -- Unlike `enabled` (which prevents registration entirely), `cond` allows
  -- manual loading via :PackLoad even when auto-load is skipped
  if spec.cond ~= nil then
    lzn.load = function(plugin_name)
      -- Check if this is a forced load (via :PackLoad) - bypass cond
      if force_load[plugin_name] then
        force_load[plugin_name] = nil
        vim.cmd.packadd(plugin_name)
        return
      end

      -- Evaluate cond
      local cond = spec.cond
      if type(cond) == 'function' then
        local ok, result = pcall(cond)
        if not ok then
          vim.notify('pack.lua: cond() error for ' .. plugin_name .. ': ' .. tostring(result), vim.log.levels.WARN)
          cond = false
        else
          cond = result
        end
      end

      -- Skip loading if cond is false
      if cond == false then
        return
      end

      vim.cmd.packadd(plugin_name)
    end
  end

  -- beforeAll: run init code that doesn't require the plugin
  -- This runs at startup for ALL plugins, before any are loaded
  -- EXCEPTION: For high-priority plugins (colorschemes), init likely needs
  -- the plugin loaded first, so we skip beforeAll and run init in after instead
  local is_high_priority = spec.priority and spec.priority >= 1000
  if spec.init and not is_high_priority then
    lzn.beforeAll = spec.init
  end

  -- before: load dependencies (runs right before this plugin's packadd)
  -- Also set current_trigger for accurate tracking based on spec's trigger types
  local orig_before = nil
  if spec.dependencies then
    orig_before = function()
      for _, dep in ipairs(to_array(spec.dependencies)) do
        local dep_name = type(dep) == 'string' and get_name(dep) or get_name(dep[1])
        -- Mark dependency trigger before loading
        current_trigger = 'dependency'
        require('lz.n').trigger_load(dep_name)
        -- Force require the main module to ensure it's loaded before next dep
        -- This is needed because some plugins (e.g. nvim-treesitter-textobjects)
        -- have plugin/*.vim files that require their dependencies' modules
        local dep_spec = type(dep) == 'string' and { dep } or dep
        local dep_main = get_main(dep_name, dep_spec.main)
        if dep_main then
          pcall(require, dep_main)
        end
      end
    end
  end

  -- Determine the primary trigger for this plugin (used by before hook)
  local primary_trigger = nil
  if spec.colorscheme then
    primary_trigger = 'colorscheme'
  elseif spec.priority and spec.priority >= 1000 then
    primary_trigger = 'startup'
  elseif spec.lazy == false then
    primary_trigger = 'startup'
  end
  -- Note: event/cmd/ft/keys triggers are set dynamically below

  lzn.before = function()
    -- Set current_trigger based on what we know about this plugin
    -- For event/cmd/ft/keys, we detect from context; for others, use primary_trigger
    if not current_trigger then
      if primary_trigger then
        current_trigger = primary_trigger
      elseif spec.event then
        -- Try to detect from vim.v.event if available
        local ev = vim.v.event
        if ev and ev.event then
          current_trigger = 'event:' .. ev.event
        else
          local first_ev = type(spec.event) == 'table' and spec.event[1] or spec.event
          first_ev = type(first_ev) == 'table' and first_ev.event or first_ev
          current_trigger = 'event:' .. tostring(first_ev)
        end
      elseif spec.cmd then
        local first_cmd = type(spec.cmd) == 'table' and spec.cmd[1] or spec.cmd
        current_trigger = 'cmd:' .. first_cmd
      elseif spec.ft then
        local first_ft = type(spec.ft) == 'table' and spec.ft[1] or spec.ft
        current_trigger = 'ft:' .. first_ft
      elseif spec.keys then
        local first_key = type(spec.keys) == 'table' and (type(spec.keys[1]) == 'table' and spec.keys[1][1] or spec.keys[1]) or spec.keys
        current_trigger = 'key:' .. tostring(first_key)
      end
    end
    -- Run original before hook (dependencies)
    if orig_before then
      orig_before()
    end
  end

  -- after: run config/opts (only if needed)
  -- For high-priority plugins, also run init here (after packadd)
  -- Also track loaded state and timing for :PackList and :PackProfile
  local needs_after = spec.config or spec.opts or (spec.init and is_high_priority)
  if needs_after then
    lzn.after = function()
      local start_time = vim.uv.hrtime()

      -- Track that this plugin has been loaded
      loaded_plugins[name] = get_trigger(name)

      -- For high-priority plugins (colorschemes), run init after load
      if spec.init and is_high_priority then
        spec.init()
      end

      -- Run config function if provided
      -- lazy.nvim signature: config(plugin, opts) - we pass (_, opts) for compatibility
      if type(spec.config) == 'function' then
        spec.config(nil, spec.opts or {})
        load_times[name] = (vim.uv.hrtime() - start_time) / 1e6
        return
      end

      -- Auto-setup with opts (when config = true or just opts provided)
      if spec.opts or spec.config == true then
        local main = get_main(name, spec.main)
        if main then
          local ok, mod = pcall(require, main)
          if ok and mod.setup then
            mod.setup(spec.opts or {})
          end
        end
      end

      load_times[name] = (vim.uv.hrtime() - start_time) / 1e6
    end
  else
    -- Even without config/opts, track loaded state and minimal timing
    lzn.after = function()
      loaded_plugins[name] = get_trigger(name)
      load_times[name] = 0 -- No config time, just packadd
    end
  end

  return lzn
end
--- Setup plugins
---@param specs (string|PackSpec)[]
function M.setup(specs)
  -- Expand any { import = 'module.path' } specs
  specs = expand_imports(specs)

  local pack_specs = {}
  local lzn_specs = {}

  for _, spec in ipairs(specs) do
    -- Normalize string specs
    if type(spec) == 'string' then
      spec = { spec }
    end

    -- Skip disabled plugins (evaluate function if needed)
    local enabled = spec.enabled
    if type(enabled) == 'function' then
      local ok, result = pcall(enabled)
      enabled = ok and result
    end
    if enabled == false then
      goto continue
    end

    -- Handle local plugins (dir field) - symlink instead of git clone
    if spec.dir then
      local name = spec.name or get_name(spec[1])
      local expanded = vim.fn.expand(spec.dir)

      if vim.fn.isdirectory(expanded) == 0 then
        vim.notify('pack.lua: dir not found: ' .. spec.dir, vim.log.levels.ERROR)
        goto continue
      end

      local pack_dir = vim.fn.stdpath 'data' .. '/site/pack/core/opt'
      local link_path = pack_dir .. '/' .. name

      -- Create symlink if not exists (or if it's a broken link)
      if vim.fn.isdirectory(link_path) == 0 then
        vim.fn.mkdir(pack_dir, 'p')
        local result = vim.fn.system { 'ln', '-sf', expanded, link_path }
        if vim.v.shell_error ~= 0 then
          vim.notify('pack.lua: failed to symlink ' .. name .. ': ' .. result, vim.log.levels.ERROR)
          goto continue
        end
      end

      -- Track as local plugin and register with lz.n (but skip vim.pack)
      plugins[name] = spec
      local_plugins[name] = expanded
      table.insert(lzn_specs, to_lzn_spec(spec))
      goto continue
    end

    local name = get_name(spec[1])
    plugins[name] = spec

    -- Build vim.pack spec
    local pack_spec = { src = to_url(spec[1]) }
    if spec.name then
      pack_spec.name = spec.name
    end
    pack_spec.version = build_version_spec(spec)
    table.insert(pack_specs, pack_spec)

    -- Register build hook
    if spec.build then
      build_hooks[get_name(spec[1])] = spec.build
    end

    -- Collect dependencies and register them with lz.n (recursive)
    local function process_dependencies(deps)
      for _, dep in ipairs(to_array(deps)) do
        local dep_spec = type(dep) == 'string' and { dep } or dep
        local dep_name = get_name(dep_spec[1])

        if not plugins[dep_name] then
          plugins[dep_name] = dep_spec

          -- Build vim.pack spec for dependency
          local dep_pack_spec = { src = to_url(dep_spec[1]) }
          dep_pack_spec.version = build_version_spec(dep_spec)
          table.insert(pack_specs, dep_pack_spec)

          if dep_spec.build then
            build_hooks[get_name(dep_spec[1])] = dep_spec.build
          end

          -- Recursively process nested dependencies first
          if dep_spec.dependencies then
            process_dependencies(dep_spec.dependencies)
          end

          -- Register dependency with lz.n so trigger_load works
          -- Set lazy = true explicitly so deps are only loaded when triggered
          -- via the parent plugin's `before` hook, not eagerly at startup
          local dep_lzn_spec = to_lzn_spec(dep_spec)
          dep_lzn_spec.lazy = true
          table.insert(lzn_specs, dep_lzn_spec)
        end
      end
    end
    process_dependencies(spec.dependencies)

    -- Build lz.n spec
    table.insert(lzn_specs, to_lzn_spec(spec))

    ::continue::
  end

  -- Install plugins via vim.pack (only if needed)
  if #pack_specs > 0 then
    -- Include lz.n itself
    table.insert(pack_specs, 1, 'https://github.com/lumen-oss/lz.n.git')

    -- Store specs for :PackSync command
    M._pack_specs = pack_specs

    -- Check if lz.n is already installed (proxy for "first run" detection)
    local lzn_path = vim.fn.stdpath 'data' .. '/site/pack/core/opt/lz.n'
    local is_first_run = vim.fn.isdirectory(lzn_path) == 0

    if is_first_run then
      -- First run: store specs for later, prompt user to install
      M._pending_specs = pack_specs
      vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function()
          vim.notify('Plugins not installed. Run :PackInstall to install ' .. #pack_specs .. ' plugins.', vim.log.levels.WARN)
        end,
      })
      M.create_commands()
      return -- Don't setup lz.n yet, plugins aren't available
    end
    -- NOTE: We intentionally do NOT call vim.pack.add() here on subsequent runs.
    -- vim.pack.add() modifies runtimepath, causing Neovim to source plugin/ files
    -- at startup before lz.n can manage load order. Since plugins are already
    -- installed in pack/core/opt/, packadd will find them when lz.n loads them.
  end

  -- Setup build hooks
  vim.api.nvim_create_autocmd('User', {
    pattern = 'PackChanged',
    callback = function(args)
      local build = build_hooks[args.data.spec.name]
      if build and args.data.kind ~= 'delete' then
        vim.notify('Building ' .. args.data.spec.name .. '...', vim.log.levels.INFO)
        if type(build) == 'function' then
          build(args.data.path)
        elseif build:sub(1, 1) == ':' then
          vim.cmd(build:sub(2))
        else
          vim.fn.system { 'sh', '-c', 'cd ' .. args.data.path .. ' && ' .. build }
        end
      end
    end,
  })

  -- Load lz.n and register all plugin specs
  -- Must defer until after VimEnter because vim.pack.add during init.lua
  -- behaves like :packadd! (doesn't source plugin files until load-plugins step)
  vim.cmd.packadd 'lz.n'

  -- Register custom handlers that track what actually triggered each plugin load
  -- We wrap lz.n's loader.load to capture the trigger before the after hook runs
  local lzn = require 'lz.n'
  local original_trigger_load = lzn.trigger_load

  -- Wrap trigger_load to set current_trigger before loading
  ---@diagnostic disable-next-line: duplicate-set-field
  lzn.trigger_load = function(name_or_names, opts)
    -- If current_trigger is already set (e.g., by our event/cmd/key hooks), keep it
    -- Otherwise default to 'api' (direct trigger_load call)
    if not current_trigger and not loaded_plugins[name_or_names] then
      current_trigger = 'api'
    end
    return original_trigger_load(name_or_names, opts)
  end

  local function load_lzn()
    require('lz.n').load(lzn_specs)

    -- FIX: Trigger plugins with early events (VimEnter/UIEnter/DeferredUIEnter) that already fired
    -- These events fire before lz.n loads, so we need to manually trigger these plugins.
    -- Use vim.schedule to ensure lz.n has fully initialized its handlers first.
    vim.schedule(function()
      for _, spec in ipairs(lzn_specs) do
        local name = spec[1]
        -- Skip if already loaded
        if loaded_plugins[name] then
          goto continue
        end

        if spec.event then
          local events = type(spec.event) == 'string' and { spec.event } or spec.event
          for _, ev in ipairs(events) do
            local event_name = type(ev) == 'string' and ev or (type(ev) == 'table' and ev.event)
            -- Handle all early events that fire before/during lz.n initialization
            if event_name == 'VimEnter' or event_name == 'UIEnter' or event_name == 'DeferredUIEnter' then
              -- Mark trigger before loading so get_trigger() can detect it
              loaded_plugins[name] = 'event:' .. event_name
              pcall(require('lz.n').trigger_load, name)
              break
            end
          end
        end
        ::continue::
      end
    end)
  end

  if vim.v.vim_did_enter == 1 then
    load_lzn()
  else
    vim.api.nvim_create_autocmd('VimEnter', {
      once = true,
      callback = load_lzn,
    })
  end

  M.create_commands()
end

--- Manually trigger a plugin load
---@param name string
function M.load(name)
  require('lz.n').trigger_load(name)
end

--- List registered plugins
---@return string[]
function M.plugins()
  local names = vim.tbl_keys(plugins)
  table.sort(names)
  return names
end

--- Create helper commands
function M.create_commands()
  vim.api.nvim_create_user_command('PackUpdate', function(args)
    local names = nil
    if args.args and args.args ~= '' then
      names = vim.split(args.args, '%s+')
    end
    vim.pack.update(names)
  end, { nargs = '*', complete = M.plugins, desc = 'Update plugins (all or specified)' })

  vim.api.nvim_create_user_command('PackSync', function()
    -- Sync plugins to their specified versions/branches/tags
    if not M._pack_specs or #M._pack_specs == 0 then
      vim.notify('No plugin specs to sync.', vim.log.levels.WARN)
      return
    end

    local pack_dir = vim.fn.stdpath 'data' .. '/site/pack/core/opt'
    local synced = 0

    for _, spec in ipairs(M._pack_specs) do
      local src = type(spec) == 'string' and spec or spec.src
      local name = type(spec) == 'table' and spec.name or src:match '[^/]+$':gsub('%.git$', '')
      local version = type(spec) == 'table' and spec.version or nil
      local plugin_path = pack_dir .. '/' .. name

      if vim.fn.isdirectory(plugin_path) == 1 and version then
        local target = nil

        if type(version) == 'string' then
          -- Exact branch/tag/commit
          target = version
        elseif type(version) == 'table' and version.has then
          -- vim.version.range() object - find matching tag
          vim.fn.system { 'git', '-C', plugin_path, 'fetch', '--tags', '--quiet' }
          local tags_output = vim.fn.system { 'git', '-C', plugin_path, 'tag', '-l', '--sort=-v:refname' }
          for tag in tags_output:gmatch '[^\n]+' do
            local parsed = vim.version.parse(tag)
            if parsed and version:has(parsed) then
              target = tag
              break
            end
          end
        end

        if target then
          local result = vim.fn.system { 'git', '-C', plugin_path, 'checkout', target, '--quiet' }
          if vim.v.shell_error == 0 then
            synced = synced + 1
            vim.notify(string.format('Synced %s to %s', name, target), vim.log.levels.INFO)
          else
            vim.notify(string.format('Failed to sync %s: %s', name, result), vim.log.levels.ERROR)
          end
        end
      end
    end

    if synced > 0 then
      vim.notify(string.format('Synced %d plugins. Restart Neovim to apply changes.', synced), vim.log.levels.INFO)
    else
      vim.notify('No plugins needed syncing.', vim.log.levels.INFO)
    end
  end, { desc = 'Sync plugins to specified versions/branches' })

  vim.api.nvim_create_user_command('PackInstall', function()
    if M._pending_specs then
      vim.notify('Installing ' .. #M._pending_specs .. ' plugins...', vim.log.levels.INFO)
      vim.pack.add(M._pending_specs)
      M._pending_specs = nil
      vim.notify('Installation complete. Please restart Neovim.', vim.log.levels.INFO)
    else
      vim.notify('No pending plugins to install.', vim.log.levels.INFO)
    end
  end, { desc = 'Install pending plugins' })

  vim.api.nvim_create_user_command('PackList', function()
    local pack_dir = vim.fn.stdpath 'data' .. '/site/pack/core/opt'
    local lines = {}

    for _, name in ipairs(M.plugins()) do
      local trigger = loaded_plugins[name]
      local loaded = trigger ~= nil
      local plugin_path = pack_dir .. '/' .. name

      -- Get version info from git
      local version = ''
      if vim.fn.isdirectory(plugin_path) == 1 then
        local tag = vim.fn.system { 'git', '-C', plugin_path, 'describe', '--tags', '--exact-match', 'HEAD' }
        if vim.v.shell_error == 0 then
          version = vim.trim(tag)
        else
          local commit = vim.fn.system { 'git', '-C', plugin_path, 'rev-parse', '--short', 'HEAD' }
          if vim.v.shell_error == 0 then
            version = vim.trim(commit)
          end
        end
      end

      local status = loaded and '✓' or '○'
      local trigger_info = trigger or ''
      
      -- Format: status name (trigger) version
      if trigger_info ~= '' then
        table.insert(lines, string.format('%s %-25s %-20s %s', status, name, '(' .. trigger_info .. ')', version))
      else
        table.insert(lines, string.format('%s %-25s %-20s %s', status, name, '', version))
      end
    end

    print(table.concat(lines, '\n'))
  end, { desc = 'List plugins with load triggers and versions' })

  vim.api.nvim_create_user_command('PackLoad', function(args)
    -- Set force_load flag to bypass cond check
    force_load[args.args] = true
    M.load(args.args)
  end, { nargs = 1, complete = M.plugins, desc = 'Load a plugin' })

  vim.api.nvim_create_user_command('PackClean', function()
    local pack_dir = vim.fn.stdpath 'data' .. '/site/pack/core/opt'

    -- Check if pack directory exists
    if vim.fn.isdirectory(pack_dir) == 0 then
      vim.notify('No plugins directory found.', vim.log.levels.INFO)
      return
    end

    local installed = vim.fn.readdir(pack_dir) or {}
    local registered = vim.tbl_keys(plugins)

    -- lz.n is our loader, never consider it orphan
    table.insert(registered, 'lz.n')

    -- Add local plugins to registered list (they're symlinks we manage)
    for name, _ in pairs(local_plugins) do
      table.insert(registered, name)
    end

    local orphans = vim.tbl_filter(function(name)
      return not vim.tbl_contains(registered, name)
    end, installed)

    if #orphans == 0 then
      vim.notify('No orphaned plugins found.', vim.log.levels.INFO)
      return
    end

    -- Show orphans and prompt for confirmation
    local msg = 'Orphaned plugins:\n  ' .. table.concat(orphans, '\n  ') .. '\n\nRemove these plugins?'
    vim.ui.select({ 'Yes', 'No' }, { prompt = msg }, function(choice)
      if choice == 'Yes' then
        for _, name in ipairs(orphans) do
          local ok, err = pcall(vim.pack.del, name)
          if ok then
            vim.notify('Removed: ' .. name, vim.log.levels.INFO)
          else
            vim.notify('Failed to remove ' .. name .. ': ' .. tostring(err), vim.log.levels.ERROR)
          end
        end
      else
        vim.notify('Cancelled.', vim.log.levels.INFO)
      end
    end)
  end, { desc = 'Remove plugins not in current specs' })

  vim.api.nvim_create_user_command('PackProfile', function()
    local sorted = {}
    for name, ms in pairs(load_times) do
      table.insert(sorted, { name = name, ms = ms })
    end
    table.sort(sorted, function(a, b) return a.ms > b.ms end)

    local lines = { 'Plugin load times (config/setup):' }
    local total = 0
    for _, entry in ipairs(sorted) do
      table.insert(lines, string.format('%7.2f ms  %s', entry.ms, entry.name))
      total = total + entry.ms
    end

    -- Show unloaded plugins
    local unloaded = {}
    for _, name in ipairs(M.plugins()) do
      if not load_times[name] then
        table.insert(unloaded, name)
      end
    end
    if #unloaded > 0 then
      table.insert(lines, '')
      table.insert(lines, 'Not loaded:')
      for _, name in ipairs(unloaded) do
        table.insert(lines, string.format('%7s     %s', '○', name))
      end
    end

    table.insert(lines, '')
    table.insert(lines, string.format('Total: %.2f ms (%d loaded, %d pending)', total, #sorted, #unloaded))

    print(table.concat(lines, '\n'))
  end, { desc = 'Show plugin load times' })
end

return M
