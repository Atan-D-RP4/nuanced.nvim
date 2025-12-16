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
---@field enabled? boolean|fun():boolean Whether plugin is enabled (default: true)
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
---@field import? string Module path to import additional specs from

-- Internal state
local plugins = {}
local build_hooks = {}

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

--- Get the full plugin name (same as get_name now)
local function get_full_name(src)
  return get_name(src)
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

--- Convert our spec to lz.n spec format
---@param spec PackSpec
---@return table lz.n spec
local function to_lzn_spec(spec)
  local name = spec.name or get_full_name(spec[1])
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

  -- beforeAll: run init code that doesn't require the plugin
  -- This runs at startup for ALL plugins, before any are loaded
  -- EXCEPTION: For high-priority plugins (colorschemes), init likely needs
  -- the plugin loaded first, so we skip beforeAll and run init in after instead
  local is_high_priority = spec.priority and spec.priority >= 1000
  if spec.init and not is_high_priority then
    lzn.beforeAll = spec.init
  end

  -- before: load dependencies (runs right before this plugin's packadd)
  if spec.dependencies then
    lzn.before = function()
      for _, dep in ipairs(to_array(spec.dependencies)) do
        local dep_name = type(dep) == 'string' and get_full_name(dep) or get_full_name(dep[1])
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

  -- after: run config/opts (only if needed)
  -- For high-priority plugins, also run init here (after packadd)
  local needs_after = spec.config or spec.opts or (spec.init and is_high_priority)
  if needs_after then
    lzn.after = function()
      -- For high-priority plugins (colorschemes), run init after load
      if spec.init and is_high_priority then
        spec.init()
      end

      -- Run config function if provided
      -- lazy.nvim signature: config(plugin, opts) - we pass (_, opts) for compatibility
      if type(spec.config) == 'function' then
        spec.config(nil, spec.opts or {})
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

    -- Skip disabled plugins
    if spec.enabled == false then
      goto continue
    end

    local name = get_name(spec[1])
    plugins[name] = spec

    -- Build vim.pack spec
    local pack_spec = { src = to_url(spec[1]) }
    if spec.name then
      pack_spec.name = spec.name
    end
    -- vim.pack's `version` accepts: vim.version.range(), branch name, tag, or commit hash
    -- Convert lazy.nvim-style semver strings (e.g., '1.*', '^1.0.0') to vim.version.range()
    if spec.version then
      if type(spec.version) == 'string' and spec.version:match '[%*%^~>=<]' then
        -- Semver pattern - convert to vim.version.range()
        pack_spec.version = vim.version.range(spec.version)
      else
        -- Exact version, branch, tag, or already a range object
        pack_spec.version = spec.version
      end
    elseif spec.branch then
      pack_spec.version = spec.branch
    elseif spec.tag then
      pack_spec.version = spec.tag
    elseif spec.commit then
      pack_spec.version = spec.commit
    end
    table.insert(pack_specs, pack_spec)

    -- Register build hook
    if spec.build then
      build_hooks[get_full_name(spec[1])] = spec.build
    end

    -- Collect dependencies and register them with lz.n (recursive)
    local function process_dependencies(deps)
      for _, dep in ipairs(to_array(deps)) do
        local dep_spec = type(dep) == 'string' and { dep } or dep
        local dep_name = get_name(dep_spec[1])

        if not plugins[dep_name] then
          plugins[dep_name] = dep_spec

          -- Build vim.pack spec for dependency with version/branch/tag/commit
          local dep_pack_spec = { src = to_url(dep_spec[1]) }
          if dep_spec.version then
            if type(dep_spec.version) == 'string' and dep_spec.version:match '[%*%^~>=<]' then
              dep_pack_spec.version = vim.version.range(dep_spec.version)
            else
              dep_pack_spec.version = dep_spec.version
            end
          elseif dep_spec.branch then
            dep_pack_spec.version = dep_spec.branch
          elseif dep_spec.tag then
            dep_pack_spec.version = dep_spec.tag
          elseif dep_spec.commit then
            dep_pack_spec.version = dep_spec.commit
          end
          table.insert(pack_specs, dep_pack_spec)

          if dep_spec.build then
            build_hooks[get_full_name(dep_spec[1])] = dep_spec.build
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
      M._pending_lzn_specs = lzn_specs
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
  if vim.v.vim_did_enter == 1 then
    require('lz.n').load(lzn_specs)
  else
    vim.api.nvim_create_autocmd('VimEnter', {
      once = true,
      callback = function()
        require('lz.n').load(lzn_specs)
      end,
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
      local loaded = package.loaded[name] ~= nil
      local plugin_path = pack_dir .. '/' .. name

      -- Get version info from git
      local version = ''
      if vim.fn.isdirectory(plugin_path) == 1 then
        local tag = vim.fn.system { 'git', '-C', plugin_path, 'describe', '--tags', '--exact-match', 'HEAD' }
        if vim.v.shell_error == 0 then
          version = vim.trim(tag)
        else
          -- Not on a tag, show branch and short commit
          local branch = vim.fn.system { 'git', '-C', plugin_path, 'rev-parse', '--abbrev-ref', 'HEAD' }
          local commit = vim.fn.system { 'git', '-C', plugin_path, 'rev-parse', '--short', 'HEAD' }
          if vim.v.shell_error == 0 then
            version = vim.trim(branch) .. '@' .. vim.trim(commit)
          end
        end
      end

      local status = loaded and '✓' or '○'
      table.insert(lines, string.format('%s %-30s %s', status, name, version))
    end

    print(table.concat(lines, '\n'))
  end, { desc = 'List plugins with versions' })

  vim.api.nvim_create_user_command('PackLoad', function(args)
    M.load(args.args)
  end, { nargs = 1, complete = M.plugins, desc = 'Load a plugin' })
end

return M
