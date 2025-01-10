return {
  {
    'ThePrimeagen/git-worktree.nvim',
    event = 'VeryLazy',

    dependencies = {
      'nvim-lua/plenary.nvim',
      'ibhagwan/fzf-lua',
    },

    config = function()
      local fzf = require 'fzf-lua'
      local utils = require 'fzf-lua.utils'
      local path = require 'fzf-lua.path'
      local git_worktree = require 'git-worktree'

      -- Keep track of force deletion state
      local force_next_deletion = false

      -- Helper function to parse git worktree list
      local function parse_worktree_list()
        local output = utils.io_system { 'git', 'worktree', 'list' }
        if not output then
          return {}
        end

        local results = {}
        for line in output:gmatch '[^\r\n]+' do
          local fields = vim.split(line:gsub('%s+', ' '), ' ')
          if fields[2] ~= '(bare)' then
            table.insert(results, {
              path = fields[1],
              sha = fields[2],
              branch = fields[3],
              display = string.format('%-20s %-40s %s', fields[3]:gsub('[%[%]]', ''), path.normalize(fields[1]), fields[2]),
            })
          end
        end
        return results
      end

      -- Switch to selected worktree
      local function switch_worktree(selected)
        if not selected then
          return
        end
        local worktree = parse_worktree_list()[selected[1]]
        if worktree then
          git_worktree.switch_worktree(worktree.path)
        end
      end

      -- Handlers for delete operations
      local function delete_success_handler()
        force_next_deletion = false
        print 'Worktree deleted successfully'
      end

      local function delete_failure_handler()
        print 'Deletion failed, use <C-f> to force the next deletion'
      end

      -- Delete worktree with confirmation
      local function delete_worktree(selected)
        if not selected then
          return
        end
        local worktree = parse_worktree_list()[selected[1]]
        if not worktree then
          return
        end

        local confirm_msg = force_next_deletion and 'Force delete worktree ' .. worktree.path .. '? [y/N] ' or 'Delete worktree ' .. worktree.path .. '? [y/N] '

        local confirmed = vim.fn.input(confirm_msg)
        if confirmed:lower():sub(1, 1) ~= 'y' then
          print 'Worktree deletion cancelled'
          return
        end

        git_worktree.delete_worktree(worktree.path, force_next_deletion, {
          on_success = delete_success_handler,
          on_failure = delete_failure_handler,
        })
      end

      -- Create new worktree
      local function create_worktree()
        -- Get available branches
        local branches = utils.io_system { 'git', 'branch', '-a' }
        if not branches then
          return
        end

        local branch_list = {}
        for branch in branches:gmatch '[^\r\n]+' do
          branch = branch:gsub('^%s*%*?%s*', ''):gsub('^remotes/[^/]+/', '')
          if not vim.tbl_contains(branch_list, branch) then
            table.insert(branch_list, branch)
          end
        end

        fzf.fzf_exec(branch_list, {
          prompt = 'Select branch > ',
          actions = {
            ['default'] = function(selected)
              if not selected then
                return
              end
              local branch = selected[1]
              local path = vim.fn.input 'Worktree path > '
              if path == '' then
                return
              end

              git_worktree.create_worktree(path, branch)
            end,
          },
        })
      end

      -- Main worktree selector function
      local function worktree_selector()
        local worktrees = parse_worktree_list()
        local displays = {}
        for _, wt in ipairs(worktrees) do
          table.insert(displays, wt.display)
        end

        fzf.fzf_exec(displays, {
          prompt = 'Git Worktrees > ',
          actions = {
            ['default'] = switch_worktree,
            ['ctrl-d'] = delete_worktree,
            ['ctrl-f'] = function()
              force_next_deletion = not force_next_deletion
              local msg = force_next_deletion and 'The next deletion will be forced' or 'The next deletion will not be forced'
              print(msg)
            end,
          },
        })
      end

      -- Setup the git-worktree plugin
      git_worktree.setup()

      -- Set up keymaps for the worktree operations
      vim.keymap.set('n', '<leader>ww', worktree_selector, {
        desc = '[W]orktree [W]orkspace selector',
      })
      vim.keymap.set('n', '<leader>wc', create_worktree, {
        desc = '[W]orktree [C]reate',
      })

      -- Optional: Configure hooks
      git_worktree.on_tree_change(function(op, metadata)
        if op == git_worktree.Operations.Switch then
          print('Switched to worktree: ' .. metadata.path)
        elseif op == git_worktree.Operations.Create then
          print('Created worktree: ' .. metadata.path)
        elseif op == git_worktree.Operations.Delete then
          print('Deleted worktree: ' .. metadata.path)
        end
      end)
    end,
  },
}
