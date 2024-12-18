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
    enabled = false,
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

      keys = {
        { '<leader>fh', '<cmd>lua require("telescope.builtin").help_tags()<CR>', desc = '[F]ind [H]elp Tags', mode = 'n' },
        { '<leader>fk', '<cmd>lua require("telescope.builtin").keymaps()<CR>', desc = '[F]ind [K]eymaps', mode = 'n' },
        { '<leader>ff', '<cmd>lua require("telescope.builtin").files()<CR>', desc = '[F]ind [F]iles', mode = 'n' },
        { '<leader>fb', '<cmd>lua require("telescope.builtin").builtin()<CR>', desc = '[F]ind [B]uiltin', mode = 'n' },
        { '<leader>fw', '<cmd>lua require("telescope.builtin").grep_string()<CR>', desc = '[F]ind [W]ord', mode = 'n' },
        { '<leader>fg', '<cmd>lua require("telescope.builtin").live_grep()<CR>', desc = '[F]ind by [G]rep', mode = 'n' },
        { '<leader>fd', '<cmd>lua require("telescope.builtin").diagnostics()<CR>', desc = '[F]ind [D]iagnostics', mode = 'n' },
        { '<leader>fr', '<cmd>lua require("telescope.builtin").resume()<CR>', desc = '[F]ind [R]esume', mode = 'n' },
        { '<leader>fo', '<cmd>lua require("telescope.builtin").oldfiles()<CR>', desc = '[F]ind [O]ld Files', mode = 'n' },
        { '<leader>fb', '<cmd>lua require("telescope.builtin").buffers()<CR>', desc = '[F]ind [B]uffers', mode = 'n' },
        { '<leader>fc', '<cmd>lua require("telescope.builtin").command_history()<CR>', desc = '[F]ind [C]ommands', mode = 'n' },

        {
          '<leader>fn',
          '<cmd>lua require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config"), follow = true })<CR>',
          desc = '[F]ind [N]vim files',
          mode = 'n',
        },
        {
          '<leader>/?',
          '<cmd>lua require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown { winblend = 10, previewer = false })<CR>',
          desc = '[/] Fuzzily search in current buffer',
          mode = 'n',
        },
        {
          '<leader>?',
          '<cmd>lua require("telescope.builtin").live_grep(require("telescope.themes").get_dropdown { winblend = 10, previewer = false })<CR>',
          desc = '[S]earch [/] in Open Files',
          mode = 'n',
        },
      },
      -- Useful for getting pretty icons, but requires a Nerd Font.
      -- { 'echasnovski/mini.icons', event = 'VeryLazy', enabled = vim.g.have_nerd_font },
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
            -- prompt_position = "top",
            flex = {
              -- use vertical layout when window column < filp_columns
              flip_columns = 160,
            },
            vertical = {
              height = 0.8,
              width = 120,
              preview_height = 0.4,
              mirror = true, -- flip location of results/prompt and preview windows
              -- prompt_position = "top",
            },
            horizontal = {
              -- mirror = true,
              width = 0.85,
              preview_width = 0.6,
            },
            center = {
              -- mirror = true,
            },
            bottom_pane = {
              height = { 0.5, min = 25, max = 50 },
            },
          },

          file_ignore_patterns = { 'node_modules', '/dist', 'target' },

          preview = {
            hide_on_startup = false,
          },

          path_display = {
            'truncate', -- truncate long file name
            'smart',
            'filename_first',
          },

          mappings = {
            i = {
              ['<c-enter>'] = 'to_fuzzy_refine',
              ['<CR>'] = custom.multi_open,
              ['<c-d>'] = custom.buf_del,
            },
            n = {
              ['<CR>'] = custom.multi_open,
              ['<c-d>'] = custom.buf_del,
            },
          },

          pickers = {
            buffers = {
              sort_mru = true,
              sort_lastused = true,
              ignore_current_buffer = true,
            },
          },

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
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
