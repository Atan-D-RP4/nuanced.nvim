M = {
  'nvim-treesitter/nvim-treesitter-textobjects',
  event = { 'BufRead', 'BufNewFile' },
  enabled = true,

  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  main = 'nvim-treesitter.configs',
}

M.opts = {}

---@module 'nvim-treesitter.configs'
---@type nvim-treesitter.configs.Config
M.opts.textobjects = {
  select = {
    enable = true,
    lookahead = true,

    keymaps = {
      -- You can use the capture groups defined in textobjects.scm
      ['a='] = { query = '@assignment.outer', desc = 'Select outer part of an assignment' },
      ['i='] = { query = '@assignment.inner', desc = 'Select inner part of an assignment' },

      ['aa'] = { query = '@parameter.outer', desc = 'Select outer part of a parameter/[a]rgument' },
      ['ia'] = { query = '@parameter.inner', desc = 'Select inner part of a parameter/[a]rgument' },

      ['ai'] = { query = '@conditional.outer', desc = 'Select outer part of an [i]f conditional' },
      ['ii'] = { query = '@conditional.inner', desc = 'Select inner part of an [i]f conditional' },

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

  move = {
    enable = true,
    set_jumps = true, -- whether to set jumps in the jumplist
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
}

return M
