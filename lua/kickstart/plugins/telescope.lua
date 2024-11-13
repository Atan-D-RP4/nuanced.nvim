local custom = {
  multi_open = function(prompt_bufnr)
    local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
    local multi = picker:get_multi_selection()

    if vim.tbl_isempty(multi) then
      require('telescope.actions').select_default(prompt_bufnr)
      return
    end

    require('telescope.actions').close(prompt_bufnr)
    for _, entry in pairs(multi) do
      local filename = entry.filename or entry.value
      local line = entry.lnum or 1
      local col = entry.col or 1

      vim.cmd(string.format('e +%d %s', line, filename))
      vim.cmd(string.format('normal! %d|', col))
    end
  end,

  buf_del = function(prompt_bufnr)
    local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
    local selection = picker:get_selection()

    if vim.fn.buflisted(selection.bufnr) == 1 then
      require('telescope.actions').delete_buffer(prompt_bufnr)
    else
      print 'Buffer is not open'
    end
  end,

  grep_args = function()
    if vim.fn.executable 'rg' == 1 then
      return {
        'rg',
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
      }
    else
      return {
        'grep',
        '--extended-regexp',
        '--color=never',
        '--with-filename',
        '--line-number',
        '-b', -- grep doesn't support a `--column` option :(
        '--ignore-case',
        '--recursive',
        '--no-messages',
        '--exclude-dir=*cache*',
        '--exclude-dir=*.git',
        '--exclude=.*',
        '--binary-files=without-match',
      }
    end
  end,
}
-- NOTE: Plugins can specify dependencies.
--
-- The dependencies are proper plugin specifications as well - anything
-- you do for a plugin at the top level, you can do for a dependency.
--
-- Use the `dependencies` key to specify the dependencies of a particular plugin

return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VeryLazy',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',
        event = 'VeryLazy',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim', event = 'VeryLazy' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },

    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        defaults = {
          -- Window settings
          layout_config = {
            prompt_position = 'bottom',
            preview_cutoff = 120,
            width = 0.85,
            height = 0.85,
          },

          mappings = {
            i = {
              ['<c-enter>'] = 'to_fuzzy_refine',
              ['<CR>'] = custom.multi_open,
              ['<C-d>'] = custom.buf_del,
            },
            n = {
              ['<C-d>'] = custom.buf_del,
            },
          },

          pickers = {},

          vimgrep_arguments = custom.grep_args(),

          extensions = {
            ['ui-select'] = {
              require('telescope.themes').get_dropdown(),
            },
          },
        },
      }
      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- Telescope command prefix
      local prefix = '<leader>s'

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      nmap = require('utils').nmap

      nmap(prefix .. 'h', builtin.help_tags, { desc = '[S]earch [H]elp' })
      nmap(prefix .. 'k', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      nmap(prefix .. 'f', builtin.find_files, { desc = '[S]earch [F]iles' })
      nmap(prefix .. 'b', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      nmap(prefix .. 'w', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      nmap(prefix .. 'g', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      nmap(prefix .. 'd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      nmap(prefix .. 'r', builtin.resume, { desc = '[S]earch [R]esume' })
      nmap(prefix .. '.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      nmap(prefix .. '[', builtin.buffers, { desc = '[ ] Find existing buffers' })

      -- Slightly advanced example of overriding default behavior and theme
      nmap(prefix .. '/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      nmap(prefix .. '?', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your Neovim configuration files
      nmap(prefix .. 'n', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
