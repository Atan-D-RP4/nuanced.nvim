local utils = {}

function utils.is_key_mapped(modes, lhs)
  -- Normalize modes to a list if it's a single string
  if type(modes) == 'string' then
    modes = { modes }
  end

  for _, mode in ipairs(modes) do
    local mappings = vim.api.nvim_get_keymap(mode)
    for _, map in pairs(mappings) do
      if map.lhs == lhs then
        return true
      end
    end
  end

  return false
end

function utils.unmap(modes, lhs)
  -- Normalize modes to a list if it's a single string
  if type(modes) == 'string' then
    modes = { modes }
  end

  -- Delete existing mappings for all specified modes
  for _, mode in ipairs(modes) do
    if utils.is_key_mapped(mode, lhs) then
      vim.keymap.del(mode, lhs)
    end
  end
end

function utils.map(modes, lhs, rhs, opts)
  utils.unmap(modes, lhs)
  -- Set new mapping
  local options = { noremap = true, silent = true }
  if opts then
    if type(opts) == 'string' then
      opts = { desc = opts }
    end
    options = vim.tbl_extend('force', options, opts)
  end
  vim.keymap.set(modes, lhs, rhs, options)
end

function utils.nmap(lhs, rhs, opts)
  utils.map('n', lhs, rhs, opts)
end

function utils.imap(lhs, rhs, opts)
  utils.map('i', lhs, rhs, opts)
end

function utils.tmap(lhs, rhs, opts)
  utils.map('t', lhs, rhs, opts)
end

function utils.vmap(lhs, rhs, opts)
  utils.map('v', lhs, rhs, opts)
end

function utils.ternary(cond, T, F, ...)
  if cond then
    return T(...)
  else
    return F(...)
  end
end

return utils
