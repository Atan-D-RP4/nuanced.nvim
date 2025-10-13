vim.tbl_map(
  function(keys)
    require('nuance.core.utils').nmap(keys.cmd, keys.callback, keys.desc)
  end,
  vim.tbl_map(function(index)
    local mark_char = string.char(64 + index + (index == 0 and 10 or 0)) -- A=65, B=66, etc.
    return {
      cmd = '<leader>m' .. index,
      callback = function()
        vim.print('Toggling mark ' .. mark_char)
        local mark_pos = vim.api.nvim_get_mark(mark_char, {})
        if mark_pos[1] == 0 then
          vim.cmd [[ normal! gg ]]
          vim.cmd('mark ' .. mark_char)
          vim.cmd 'normal! ``' -- Jump back to where we were
        else
          vim.cmd('normal! `' .. mark_char) -- Jump to the bookmark
          vim.cmd 'normal! `"' -- Jump to the last cursor position before leaving
        end
      end,
      desc = 'Toggle [M]ark ' .. mark_char,
    }
  end, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 })
)

-- Delete mark from current buffer
require('nuance.core.utils').nmap('<leader>md', function()
  for i = 0, 9 do
    local mark_char = string.char(64 + i + (i == 0 and 10 or 0))
    local mark_pos = vim.api.nvim_get_mark(mark_char, {})

    -- Check if mark is in current buffer
    if mark_pos[1] ~= 0 and vim.api.nvim_get_current_buf() == mark_pos[3] then
      vim.cmd('delmarks ' .. mark_char)
    end
  end
end, '[M]ark [D]elete')

require('nuance.core.utils').nmap('<leader>mf', function()
  local has_snacks, snacks = pcall(require, 'snacks')
  if not has_snacks then
    return
  end
  snacks.picker.marks {
    filter_marks = 'A-I',
    transform = function(item)
      if item.label and item.label:match '^[A-I]$' and item then
        item.label = '' .. string.byte(item.label) - string.byte 'A' + 1 .. ''
        return item
      end
      return false
    end,
  }
end, '[B]ookmarks [F]inder')
