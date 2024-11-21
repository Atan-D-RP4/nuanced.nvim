-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	desc = "Resize splits when resizing the window",
	group = vim.api.nvim_create_augroup("kickstart-resize-splits", { clear = true }),
	callback = function()
		vim.cmd("wincmd =")
	end,
})

-- toggle relative number on the basis of mode
-- local augroup = vim.api.nvim_create_augroup("numbertoggle", {})
--
-- vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave", "CmdlineLeave", "WinEnter" }, {
--   pattern = "*",
--   group = augroup,
--   callback = function()
--     if vim.o.nu and vim.api.nvim_get_mode().mode ~= "i" then
--       vim.opt.relativenumber = true
--       vim.opt.number = true
--       vim.cmd("redraw")
--     end
--   end,
-- })
--
-- vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter", "CmdlineEnter", "WinLeave" }, {
--   pattern = "*",
--   group = augroup,
--   callback = function()
--     if vim.o.nu then
--       vim.opt.relativenumber = false
--       vim.opt.number = false
--       vim.cmd("redraw")
--     end
--   end,
-- })

-- don't auto comment new line
vim.api.nvim_create_autocmd("BufEnter", { command = [[set formatoptions-=cro]] })

-- NOTE: Originally tried to put this in FileType event autocmd but it is apparently
-- too early for `set modifiable` to take effect
--
-- vim.api.nvim_create_autocmd('BufWinEnter', {
--   group = vim.api.nvim_create_augroup('YOUR_GROUP_HERE', { clear = true }),
--   desc = 'allow updating quickfix window',
--   pattern = 'quickfix',
--   callback = function(ctx)
--     vim.bo.modifiable = true
--     -- :vimgrep's quickfix window display format now includes start and end column (in vim and nvim) so adding 2nd format to match that
--     vim.bo.errorformat = '%f|%l col %c| %m,%f|%l col %c-%k| %m'
--     vim.keymap.set(
--     'n',
--     '<C-s>',
--     '<Cmd>cgetbuffer|set nomodified|echo "quickfix/location list updated"<CR>',
--     { buffer = true, desc = 'Update quickfix/location list with changes made in quickfix window' }
--     )
--   end,
-- })
-- vim: ts=2 sts=2 sw=2 et
