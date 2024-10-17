return {
  'nvim-treesitter/nvim-treesitter-textobjects',

  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  main = 'nvim-treesitter.configs',

  init = function()
    local move = require 'nvim-treesitter.textobjects.move' ---@type table<string,fun(...)>
    local configs = require 'nvim-treesitter.configs'
    for name, fn in pairs(move) do
      if name:find 'goto' == 1 then
        move[name] = function(q, ...)
          if vim.wo.diff then
            local config = configs.get_module('textobjects.move')[name] ---@type table<string,string>
            for key, query in pairs(config or {}) do
              if q == query and key:find '[%]%[][cC]' then
                vim.cmd('normal! ' .. key)
                return
              end
            end
          end
          return fn(q, ...)
        end
      end
    end
  end,

  opts = {
    textobjects = {
      select = {
        enable = true,
        lookahead = true,

        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ['a='] = { query = '@assignment.outer', desc = 'Select outer part of an assignment' },
          ['i='] = { query = '@assignment.inner', desc = 'Select inner part of an assignment' },
          ['l='] = { query = '@assignment.lhs', desc = 'Select left hand side of an assignment' },
          ['r='] = { query = '@assignment.rhs', desc = 'Select right hand side of an assignment' },

          -- works for javascript/typescript files (custom captures I created in after/queries/ecma/textobjects.scm)
          ['a:'] = { query = '@property.outer', desc = 'Select outer part of an object property' },
          ['i:'] = { query = '@property.inner', desc = 'Select inner part of an object property' },
          ['l:'] = { query = '@property.lhs', desc = 'Select left part of an object property' },
          ['r:'] = { query = '@property.rhs', desc = 'Select right part of an object property' },

          ['aa'] = { query = '@parameter.outer', desc = 'Select outer part of a parameter/argument' },
          ['ia'] = { query = '@parameter.inner', desc = 'Select inner part of a parameter/argument' },

          ['ai'] = { query = '@conditional.outer', desc = 'Select outer part of a conditional' },
          ['ii'] = { query = '@conditional.inner', desc = 'Select inner part of a conditional' },

          ['al'] = { query = '@loop.outer', desc = 'Select outer part of a loop' },
          ['il'] = { query = '@loop.inner', desc = 'Select inner part of a loop' },

          ['af'] = { query = '@call.outer', desc = 'Select outer part of a function call' },
          ['if'] = { query = '@call.inner', desc = 'Select inner part of a function call' },

          ['am'] = { query = '@function.outer', desc = 'Select outer part of a method/function definition' },
          ['im'] = { query = '@function.inner', desc = 'Select inner part of a method/function definition' },

          ['ac'] = { query = '@class.outer', desc = 'Select outer part of a class' },
          ['ic'] = { query = '@class.inner', desc = 'Select inner part of a class' },

          ['a/'] = { query = '@comment.outer', desc = 'Select outer part of a comment' },
          ['i/'] = { query = '@comment.inner', desc = 'Select inner part of a comment' },
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ['<leader>na'] = '@parameter.inner', -- swap parameters/argument with next
          ['<leader>n:'] = '@property.outer', -- swap object property with next
          ['<leader>nm'] = '@function.outer', -- swap function with next
        },
        swap_previous = {
          ['<leader>pa'] = '@parameter.inner', -- swap parameters/argument with prev
          ['<leader>p:'] = '@property.outer', -- swap object property with prev
          ['<leader>pm'] = '@function.outer', -- swap function with previous
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer',
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer',
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer',
        },
      },
    },
  },
}
