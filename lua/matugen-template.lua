local M = {}
local state = rawget(_G, '__matugen_state')
if not state then
  state = {}
  _G.__matugen_state = state
end

-- Helper to apply same highlight style to multiple groups.
local function set_hl_multiple(groups, opts)
  for _, v in pairs(groups) do
    vim.api.nvim_set_hl(0, v, opts)
  end
end

local function apply_overrides()
  -- Make selected text stand out with stronger contrast.
  vim.api.nvim_set_hl(0, 'Visual', {
    bg = '{{colors.primary_container.default.hex}}',
    fg = '{{colors.on_primary_container.default.hex}}',
  })

  -- Improve string readability in low-contrast palettes.
  set_hl_multiple({ 'String', 'TSString' }, {
    fg = '{{colors.tertiary.default.hex | lighten: -15.0 }}',
  })

  -- Keep comments subtle but readable.
  set_hl_multiple({ 'TSComment', 'Comment' }, {
    fg = '{{colors.outline.default.hex}}',
    italic = true,
  })

  -- Differentiate functions and methods with distinct accent colors.
  set_hl_multiple({ 'TSMethod', 'Method' }, {
    fg = '{{colors.tertiary.default.hex}}',
  })

  -- Use a brighter accent for functions to make them pop in the code.
  set_hl_multiple({ 'TSFunction', 'Function' }, {
    fg = '{{colors.secondary.default.hex}}',
  })

  -- Highlight keywords with the primary accent color for better visibility.
  set_hl_multiple({ 'Keyword', 'TSKeyword', 'TSKeywordFunction', 'TSRepeat' }, {
    fg = '{{colors.inverse_primary.default.hex}}',
  })

  local chrome_bg = '{{colors.surface_container_lowest.default.hex}}'
  local chrome_bg_alt = '{{colors.surface_container_low.default.hex}}'
  local chrome_bg_dim = '{{colors.surface_container.default.hex}}'

  set_hl_multiple({ 'StatusLine', 'StatusLineNC', 'StatusColumn', 'SignColumn', 'FoldColumn', 'TabLine', 'WinBar', 'WinBarNC' }, {
    bg = chrome_bg,
  })

  set_hl_multiple({ 'CursorLine', 'CursorColumn' }, {
    bg = chrome_bg_alt,
  })

  vim.api.nvim_set_hl(0, 'StatusLine', {
    fg = '{{colors.on_surface.default.hex}}',
    bg = chrome_bg,
  })

  vim.api.nvim_set_hl(0, 'StatusLineNC', {
    fg = '{{colors.outline.default.hex}}',
    bg = chrome_bg,
  })

  vim.api.nvim_set_hl(0, 'TabLine', {
    fg = '{{colors.outline.default.hex}}',
    bg = chrome_bg,
  })

  vim.api.nvim_set_hl(0, 'TabLineFill', {
    bg = chrome_bg_dim,
  })

  vim.api.nvim_set_hl(0, 'TabLineSel', {
    bg = '{{colors.primary_container.default.hex}}',
    fg = '{{colors.on_primary_container.default.hex}}',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'ColorColumn', {
    bg = chrome_bg_dim,
  })
end

local matugen_names = { matugen = true }

local function register_name(name)
  if name and name ~= '' then
    matugen_names[name] = true
  end
end

local function on_colorscheme_change()
  local scheme = vim.g.colors_name or 'default'
  vim.g.current_colorscheme = scheme
  if matugen_names[scheme] then
    vim.defer_fn(apply_overrides, 0)
  end
end

local function refresh_active_matugen_theme()
  vim.notify('Refreshing active Matugen theme...', vim.log.levels.INFO, { title = 'Matugen' })
  local active_name = vim.g.colors_name or ''
  if not matugen_names[active_name] then
    return
  end

  package.loaded.matugen = nil
  require('matugen').setup(active_name)
  vim.api.nvim_exec_autocmds('ColorScheme', { pattern = active_name, modeline = false })
end

local function emit_matugen_update()
  vim.api.nvim_exec_autocmds('User', { pattern = 'MatugenUpdate', modeline = false })
end

local function schedule_matugen_update()
  vim.notify('Scheduling Matugen theme update...', vim.log.levels.INFO, { title = 'Matugen' })
  if state.pending_update then
    return
  end
  state.pending_update = true
  vim.defer_fn(function()
    state.pending_update = false
    emit_matugen_update()
  end, 80)
end

vim.api.nvim_create_augroup('MatugenThemeTracking', { clear = true })

vim.api.nvim_create_autocmd('Colorscheme', {
  group = 'MatugenThemeTracking',
  callback = on_colorscheme_change,
})

vim.api.nvim_create_autocmd('User', {
  group = 'MatugenThemeTracking',
  pattern = 'MatugenUpdate',
  callback = refresh_active_matugen_theme,
})

vim.api.nvim_create_autocmd('Signal', {
  group = 'MatugenThemeTracking',
  pattern = { 'SIGUSR1' },
  callback = schedule_matugen_update,
})

function M.setup(opts)
  local name = 'matugen'
  if type(opts) == 'string' then
    name = opts
  elseif type(opts) == 'table' and type(opts.name) == 'string' then
    name = opts.name
  end

  register_name(name)

  require('mini.base16').setup {
    use_cterm = true,
    plugins = {
      default = false,
      ['nvim-mini/mini.nvim'] = true,
    },
    palette = {
      -- Background tones
      base00 = '{{colors.background.default.hex}}',
      base01 = '{{colors.surface_container_lowest.default.hex}}',
      base02 = '{{colors.surface_container_low.default.hex}}',
      base03 = '{{colors.outline_variant.default.hex}}',

      -- Foreground tones
      base04 = '{{colors.on_surface_variant.default.hex}}',
      base05 = '{{colors.on_surface.default.hex}}',
      base06 = '{{colors.inverse_on_surface.default.hex}}',
      base07 = '{{colors.surface_bright.default.hex}}',

      -- Accent colors
      base08 = '{{colors.error.default.hex}}',
      base09 = '{{colors.tertiary.default.hex}}',
      base0A = '{{colors.secondary.default.hex}}',
      base0B = '{{colors.primary.default.hex}}',
      base0C = '{{colors.tertiary_container.default.hex}}',
      base0D = '{{colors.primary_container.default.hex}}',
      base0E = '{{colors.secondary_container.default.hex}}',
      base0F = '{{colors.secondary.default.hex | lighten: -10}}',
    },
  }

  vim.g.colors_name = name
  vim.g.current_colorscheme = name
  apply_overrides()
end

M.on_colorscheme_change = on_colorscheme_change
M.refresh_active = refresh_active_matugen_theme
M.trigger_update = emit_matugen_update

return M
