vim.g.active_session = ''
local Sessions = {}

local function create_default()
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
cd ~/
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
      table.sort(items, function(a, b)
        return a.modify_time > b.modify_time
      end)
      return items
    end,
    preview = 'preview',

    format = function(item, _)
      local ret = {}
      ret[#ret + 1] = { item.name or '', '@string' }
      return ret
    end,

    actions = {
      delete = function(picker, item, _)
        vim.notify('Deleting Session: ' .. item.name, vim.log.levels.INFO, { title = 'Session' })
        require('mini.sessions').delete(item.name, { force = true, verbose = true })
        picker:find { refresh = true }
      end,

      rename = function(picker, item, _)
        vim.ui.input({ prompt = 'Rename Session "' .. item.name .. '" to:' }, function(input)
          require('mini.sessions').delete(item.name, { force = true })
          require('mini.sessions').write(input)
          if vim.g.active_session == item.name then
            vim.g.active_session = input
          end
          picker:find { refresh = true }
        end)
      end,
    },

    win = {
      input = {
        keys = {
          ['<C-x>'] = { 'delete', desc = 'delete_session', mode = { 'n', 'i' } },
          ['<C-r>'] = { 'rename', desc = 'rename_session', mode = { 'n', 'i' } },
        },
      },
    },

    confirm = function(_, item)
      if not item then
        return
      end

      require('nuance.core.promise')
        .async_promise(100, function()
          require('mini.sessions').read(item.name, {})
          return true
        end)
        :after(function(_)
          local msg = ''
          if vim.g.active_session == '' then
            msg = 'Loaded Session: ' .. item.name
          elseif vim.g.active_session == item.name then
            msg = 'Already Loaded Session: ' .. item.name
          else
            msg = 'Switched From Session: ' .. vim.g.active_session .. '\nTo: ' .. item.name
          end
          vim.notify(msg, vim.log.levels.INFO, { title = 'Session' })
          vim.g.active_session = item.name
        end)
        .catch(function(err)
          vim.notify(err, vim.log.levels.ERROR, { title = 'Session' })
        end)
    end,
  }
end

M = {
  'echasnovski/mini.sessions',
  dependencies = {
    'folke/snacks.nvim',
  },
  event = 'VeryLazy',

  opts = {
    autoread = false,
    directory = vim.fn.stdpath 'data' .. '/sessions',
    file = '', -- File for local session (use `''` to disable)

    hooks = {
      pre = {
        read = function()
          vim.cmd [[ exec 'silent! %bwipeout!' ]]
        end,
      },
      post = {
        read = function()
          -- Exit insert mode if we are in it
          if vim.fn.mode() == 'i' then
            vim.cmd [[ stopinsert ]]
          end
        end,
      },
    },
  },
}

---@diagnostic disable-next-line: duplicate-set-field
M.config = function(_, opts)
  require('mini.sessions').setup(opts)
  vim.api.nvim_create_user_command('SessionPick', function()
    session_pick()
  end, { nargs = 0 })

  -- local read = MiniSessions.read
  -- ---@diagnostic disable-next-line: redefined-local, duplicate-set-field
  -- MiniSessions.read = function(name, opts)
  --   vim.cmd [[ exec 'silent! bufdo w' ]]
  --   read(name, opts)
  -- end

  -- Check if session dir exists and if not create it
  if vim.fn.isdirectory(require('mini.sessions').config.directory) == 0 then
    vim.fn.mkdir(vim.fn.stdpath 'data' .. '/sessions', 'p')
  end

  -- Create a default session
  create_default()

  local success, statusline = pcall(require, 'mini.statusline')
  if success == false then
    return
  end
  local default_section_filename = statusline.section_filename
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_filename = function(args)
    local session = vim.g.active_session
    if session == '' then
      -- use an icon for default session
      session = ''
    else
      session = ' ' .. session
    end
    return session .. ' ' .. default_section_filename(args)
  end
end

M.keys = {
  {
    '<leader>as',
    function()
      if vim.g.active_session == '' or vim.g.active_session == 'default' then
        vim.notify('No Active Session', vim.log.levels.INFO, { title = 'Session' })
        return
      end
      require('mini.sessions').write(vim.g.active_session)
    end,
    desc = '[S]essions [S]ave/Update',
    mode = 'n',
  },
  { '<leader>ap', '<cmd>SessionPick<CR>', desc = '[S]essions [P]ick', mode = 'n' },
  {
    '<leader>ar',
    function()
      if vim.g.active_session == '' then
        print 'No session loaded'
        return
      end
      vim.ui.input({ default = vim.g.active_session, prompt = 'Rename Session' }, function(input)
        if input == nil then
          vim.notify('Empty Session Name', vim.log.levels.ERROR, { title = 'Session' })
          return
        end
        require('mini.sessions').delete(vim.g.active_session, { force = true })
        require('mini.sessions').write(input)
        vim.g.active_session = input
      end)
    end,
    desc = '[S]ession [R]ename',
    mode = 'n',
  },
  {
    '<leader>aq',
    function()
      if vim.g.active_session == '' then
        print 'No session loaded'
        return
      end
      require('mini.sessions').write(vim.g.active_session)
      require('mini.sessions').read('default', {})
      vim.g.active_session = ''
      vim.notify('Cleared Session', vim.log.levels.INFO, { title = 'Session' })
    end,
    desc = '[S]essions [Q]uit',
    mode = 'n',
  },
  {
    '<leader>ac',
    function()
      local name = vim.fn.input 'Session name: '
      if name == '' then
        print 'No session saved'
        return
      end
      require('mini.sessions').write(name)
      vim.g.active_session = name
    end,
    desc = '[S]essions [C]reate',
    mode = 'n',
  },
}

return M
