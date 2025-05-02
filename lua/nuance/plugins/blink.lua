M = {
  'saghen/blink.cmp',
  -- event = 'VeryLazy',
  event = { 'InsertEnter', 'CmdlineEnter', 'LspAttach' },
  -- build = 'cargo build --release',

  -- use a release tag to download pre-built binaries
  version = 'v1.*',
  -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
  -- build = 'cargo build --release',
  -- If you use nix, you can build from source using latest nightly rust with:
  -- build = 'nix run .#build-plugin',
}

M.dependencies = {
  {
    'L3MON4D3/LuaSnip',
    event = { 'InsertEnter' },
    build = (function()
      -- Build Step is needed for regex support in snippets.
      -- This step is not supported in many windows environments.
      -- Remove the below condition to re-enable on windows.
      if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
        return
      end
      return 'make install_jsregexp'
    end)(),

    main = 'luasnip.config',
    opts = {
      history = true,
      updateevents = 'TextChanged,TextChangedI',
    },
    config = function()
      require 'nuance.core.luasnips'
    end,
  },
}

---@module 'blink.cmp'
---@type blink.cmp.Config
M.opts = {
  -- fuzzy = { prebuilt_binaries = { force_version = 'v0.14.*' } },
  enabled = function()
    return vim.bo.buftype ~= 'prompt' and vim.b.completion ~= false
  end,
  -- experimental signature help support
  signature = { enabled = true, window = { border = 'rounded' } },

  appearance = {
    -- Sets the fallback highlight groups to nvim-cmp's highlight groups
    -- Useful for when your theme doesn't support blink.cmp
    -- will be removed in a future release
    use_nvim_cmp_as_default = false,
    -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
    -- Adjusts spacing to ensure icons are aligned
    nerd_font_variant = 'mono',
  },
}

M.opts.completion = {
  trigger = { show_on_insert_on_trigger_character = true },

  list = {
    selection = {
      auto_insert = function(ctx)
        return ctx.mode == 'cmdline'
      end,
      preselect = function(ctx)
        return ctx.mode ~= 'cmdline'
      end,
    },
  },

  accept = { auto_brackets = { enabled = true } },

  menu = {
    border = 'rounded',
    scrollbar = false,

    cmdline_position = function()
      if vim.g.ui_cmdline_pos ~= nil then
        local pos = vim.g.ui_cmdline_pos -- (1, 0)-indexed
        return { pos[1] - 1, pos[2] }
      end
      local height = (vim.o.cmdheight == 0) and 1 or vim.o.cmdheight
      return { vim.o.lines - height, 0 }
    end,

    draw = {
      treesitter = { 'lsp' },
      columns = { { 'kind_icon', 'label', 'label_description', gap = 1 }, { 'kind', 'source_name', gap = 1 } },
      components = {
        kind = { highlight = 'Special' },
        source_name = {
          text = function(ctx)
            return ctx.source_name == 'LSP' and vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })[1].name or ctx.source_name
          end,
        },
      },
    },
  },

  documentation = {
    -- auto_show = true,
    window = { border = 'rounded' },
  },
}

-- default list of enabled providers defined so that you can extend it
-- elsewhere in your config, without redefining it, via `opts_extend`
M.opts.sources = {
  default = {
    'lsp',
    'path',
    'buffer',
    'snippets',
    'lazydev',
    --'dadbod',
  },
  providers = {
    lsp = { score_offset = 100, async = true },
    lazydev = {
      name = 'LazyDev',
      module = 'lazydev.integrations.blink',
      score_offset = 95,
    },
    path = { score_offset = 95 },
    snippets = {
      score_offset = 85,
      opts = {
        -- Whether to use show_condition for filtering snippets
        use_show_condition = true,
        -- Whether to show autosnippets in the completion list
        show_autosnippets = true,
      },
    },
    buffer = { score_offset = 80 },

    -- dadbod = {
    --   name = 'Dadbod',
    --   enabled = false,
    --   module = 'vim_dadbod_completion.blink',
    --   score_offset = 700,
    -- },
  },
}

M.opts.snippets = {
  preset = 'luasnip',
  expand = function(snippet)
    require('luasnip').lsp_expand(snippet)
  end,
  active = function(filter)
    if filter and filter.direction then
      return require('luasnip').jumpable(filter.direction)
    end
    return require('luasnip').in_snippet()
  end,
  jump = function(direction)
    require('luasnip').jump(direction)
  end,
}

M.opts.keymap = {
  ['<C-q>'] = { 'scroll_documentation_up', 'fallback' }, -- Scroll the documentation window [b]ack
  ['<C-f>'] = { 'scroll_documentation_down', 'fallback' }, -- Scroll the documentation window [f]orward

  ['<C-e>'] = { 'hide' }, -- Hide the completion menu
  ['<CR>'] = { 'select_and_accept', 'fallback' }, -- Accept the completion.
  -- ['<C-y>'] = { 'select_and_accept', 'fallback' }, -- Accept ([y]es) the completion.

  ['<C-n>'] = { 'select_next', 'snippet_forward', 'fallback' }, -- Select the [n]ext item
  ['<C-p>'] = { 'select_prev', 'snippet_backward', 'fallback' }, -- Select the [p]revious item

  -- Manually Trigger completions and toggle documentation window
  ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
}

M.opts.cmdline = {
  enabled = true,

  keymap = {
    ['<C-space>'] = { 'show', 'hide', 'fallback' },
    ['<Tab>'] = { 'show', 'select_next', 'fallback' },
    ['<S-Tab>'] = { 'show', 'select_prev', 'fallback' },
    -- ['<C-D>'] = { 'show', 'show_documentation' },
  },

  sources = function()
    local type = vim.fn.getcmdtype()
    -- Search forward and backward
    if type == '/' or type == '?' then
      return { 'buffer' }
    end
    if type == ':' or type == '@' then
      if vim.fn.getcmdline():match '.*!' ~= nil or vim.fn.getcmdline():sub(1, 6) == 'Launch' then
        return { 'path', 'buffer' }
      end
      return { 'cmdline' }
    end
    return {}
  end,

  completion = {
    list = {
      selection = {
        preselect = false,
      },
    },
    menu = {
      auto_show = true,
      draw = { columns = { { 'label', 'label_description', gap = 1 }, { 'kind_icon', 'kind', gap = 1 } } },
    },
  },
}

return M
