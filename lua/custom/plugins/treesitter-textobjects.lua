return {
  'nvim-treesitter/nvim-treesitter-textobjects',
  event = { 'BufRead', 'BufNewFile' },

  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  main = 'nvim-treesitter.configs',

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
        },
      },

      swap = {
        enable = true,
        swap_next = {
          ['<leader>na'] = { query = '@parameter.inner', desc = 'swap parameters/argument with next' },
          ['<leader>n:'] = { query = '@property.outer', desc = 'swap object property with next' },
          ['<leader>nm'] = { query = '@function.outer', desc = 'swap function with next' },
        },
        swap_previous = {
          ['<leader>pa'] = '@parameter.inner', -- swap parameters/argument with prev
          ['<leader>p:'] = '@property.outer', -- swap object property with prev
          ['<leader>pm'] = '@function.outer', -- swap function with previous
        },
      },
    },
  },

  config = function()
    local configs = require 'nvim-treesitter.configs'

    local move = require 'nvim-treesitter.textobjects.move' ---@type table<string,fun(...)>
    local select = require 'nvim-treesitter.textobjects.select' ---@type table<string,fun(...)>
    local swap = require 'nvim-treesitter.textobjects.swap' ---@type table<string,fun(...)>

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

    for name, fn in pairs(select) do
      if name:find 'goto' == 1 then
        select[name] = function(q, ...)
          if vim.wo.diff then
            local config = configs.get_module('textobjects.select')[name] ---@type table<string,string>
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

    for name, fn in pairs(swap) do
      if name:find 'goto' == 1 then
        swap[name] = function(q, ...)
          if vim.wo.diff then
            local config = configs.get_module('textobjects.swap')[name] ---@type table<string,string>
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
}
