--@param file string
vim.g.active_session = ''

local create_default = function()
  local session_path = require('mini.sessions').config.directory .. '/' .. 'default'
  local session_file = io.open(session_path, 'w')
  if session_file == nil then
    print 'Failed to create session file'
    return
  end
  session_file:write [[
let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/.local/share/nvim/sessions
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
let s:shortmess_save = &shortmess
if &shortmess =~ 'A'
  set shortmess=aoOA
else
  set shortmess=aoO
endif
argglobal
%argdel
argglobal
enew
setlocal foldmethod=manual
setlocal foldexpr=0
setlocal foldmarker={{{,}}}
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal nofoldenable
tabnext 1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0 && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20
let &shortmess = s:shortmess_save
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
set hlsearch
nohlsearch
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
  ]]
  session_file:close()
end

local session_files = function(file)
  if vim.fn.isdirectory(file) == 1 then
    return {}
  end
  local lines = {}
  local cwd, cwd_pat = '', '^cd%s*'
  local buf_pat = '^badd%s*%+%d+%s*'
  for line in io.lines(file) do
    if string.find(line, cwd_pat) then
      cwd = line:gsub('%p', '%%%1')
    end
    if string.find(line, buf_pat) then
      lines[#lines + 1] = line
    end
  end
  local buffers = {}
  for k, v in pairs(lines) do
    buffers[k] = v:gsub(buf_pat, ''):gsub(cwd:gsub('cd%s*', ''), ''):gsub('^/?%.?/', '')
  end
  local buffer_lines = table.concat(buffers, '\n')
  return buffer_lines
end

local session_pick = function()
  require('snacks.picker').pick {
    title = 'Sessions',
    finder = function()
      ---@type snacks.picker.finder.Item[]
      local items = {}
      for _, session in pairs(require('mini.sessions').detected) do
        if session.name ~= 'default' then
          table.insert(items, {
            text = session.name,
            name = session.name,
            preview = { text = session_files(session.path) },
            path = session.path,
            modify_time = os.date('%Y-%m-%d %H:%M:%S', session.modify_time),
            type = session.type,
          })
        end
      end
      return items
    end,
    preview = 'preview',

    format = function(item, _)
      local ret = {}
      ret[#ret + 1] = { item.name or '', '@string' }
      return ret
    end,

    actions = {
      delete = function(picker, item, action)
        vim.print('Action: ', action)
        vim.print('Deleting: ' .. item.name)
        require('mini.sessions').delete(item.name, { force = true, verbose = true })
        picker:find { refresh = true }
      end,
    },

    win = {
      input = {
        keys = {
          ['<C-x>'] = { 'delete', desc = 'Delete Session', mode = { 'n', 'i' } },
        },
      },
    },

    confirm = function(_, item)
      if not item then
        return
      end

      require('mini.sessions').read(item.name, {})
      local msg = ''
      if vim.g.active_session == '' then
        msg = 'Loaded Session: ' .. item.name
      else
        msg = 'Switched From Session: ' .. vim.g.active_session .. '\nTo: ' .. item.name
      end
      vim.notify(msg, vim.log.levels.INFO, { title = 'Session' })
      vim.g.active_session = item.name
    end,
  }
end

vim.api.nvim_create_user_command('SessionPick', function()
  session_pick()
end, { nargs = 0 })

M = {
  'echasnovski/mini.sessions',
  event = 'VimEnter',
  dependencies = {
    'folke/snacks.nvim',
  },
}

---@diagnostic disable-next-line: duplicate-set-field
M.config = function()
  require('mini.sessions').setup {
    autoread = false,
    directory = vim.fn.stdpath 'data' .. '/sessions',
    hooks = {
      pre = {
        read = function()
          vim.cmd [[ silent! %bwipeout! ]]
        end,
      },
    },
  }

  -- Check if session dir exists and if not create it
  if vim.fn.isdirectory(require('mini.sessions').config.directory) == 0 then
    vim.fn.mkdir(vim.fn.stdpath 'data' .. '/sessions', 'p')
  end

  -- Create a default session
  create_default()

  local statusline = require 'mini.statusline'
  local default_section_filename = statusline.section_filename
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_filename = function(args)
    local session = vim.g.active_session
    if session == nil then
      session = 'None'
    else
      session = '■ ' .. session
    end
    return session .. ' ' .. default_section_filename(args)
  end
end

M.keys = {
  { '<leader>as', '<cmd>lua require("mini.sessions").write(vim.g.current_session)<CR>', desc = '[S]essions [S]ave/Update', mode = 'n' },
  { '<leader>ap', '<cmd>SessionPick<CR>', desc = '[S]essions [P]ick', mode = 'n' },
  {
    '<leader>ac',
    function()
      require('mini.sessions').read('default', {})
      vim.g.active_session = ''
      vim.notify('Cleared Session', vim.log.levels.INFO, { title = 'Session' })
    end,
    desc = '[S]essions [C]lose',
    mode = 'n',
  },
  {
    '<leader>an',
    function()
      local name = vim.fn.input 'Session name: '
      if name == '' then
        print 'No session saved'
        return
      end
      require('mini.sessions').write(name)
      vim.g.active_session = name
    end,
    desc = '[S]essions [N]ew',
    mode = 'n',
  },
}

return M
