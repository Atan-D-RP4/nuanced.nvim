-- [[ Basic Keymaps ]]
--  See `:helpvim.keymap.set()`

-- Better Escape
vim.keymap.set("n", "<Esc>", "<C-c><C-c>", { noremap = true })
vim.keymap.set("i", "<Esc>", "<Esc><Esc><Right>", { noremap = true, desc = "Better Escape" })
-- Clear highlights on search when pressing <Esc> in normal mode

--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- NOTE: Disable arrow keys in normal mode
vim.keymap.set("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	desc = "Resize splits when resizing the window",
	group = vim.api.nvim_create_augroup("kickstart-resize-splits", { clear = true }),
	callback = function()
		vim.cmd("wincmd =")
	end,
})

-- My Keybinds
vim.keymap.set("i", "<C-U>", "<C-G>u<C-U>", { noremap = true })
vim.keymap.set("n", "<leader>'", ":terminal fish<CR>", { noremap = true, desc = "Open Terminal Buffer" })

-- Buffer Management
vim.keymap.set("n", "<leader>dd", ":bdelete! %<CR>", { noremap = true, silent = true, desc = "Delete Buffer" })
vim.keymap.set("n", "<leader>du", ":edit! #<CR>", { noremap = true, silent = true, desc = "Refresh Buffer" })

-- CTRL+S for Save
vim.keymap.set({ "n", "v", "i" }, "<C-S>", "<ESC>:update<CR>", { noremap = true, silent = true, desc = "Better Save" })

-- Re-Select Visual Selection on Re-Indent
vim.keymap.set("v", "<", "<gv", { noremap = true, desc = "Re-Select Visual Selection on Re-Indent" })
vim.keymap.set("v", ">", ">gv", { noremap = true, desc = "Re-Select Visual Selection on Re-Indent" })

-- Even Smarter J/K to Line movements
vim.keymap.set(
	{ "n", "v" },
	"j",
	"v:count ? (v:count > 5 ? 'm' . v:count : '') . 'j' : 'gj'",
	{ expr = true, noremap = true }
)
vim.keymap.set(
	{ "n", "v" },
	"k",
	"v:count ? (v:count > 5 ? 'm' . v:count : '') . 'k' : 'gk'",
	{ expr = true, noremap = true }
)

vim.keymap.set({ "n", "v" }, "<C-q>", "<C-b>", { noremap = true, silent = true })

vim.keymap.set({ "n", "v" }, "<S-w>", "b", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>.", ":<Up><CR>", { noremap = true, silent = true, desc = "Repeat Last Ex Command" })

-- Smarter Bracket Insertion
vim.keymap.set("i", "(;", "(<CR>);<Esc>O", { noremap = true })
vim.keymap.set("i", "(,", "(<CR>),<Esc>O", { noremap = true })
vim.keymap.set("i", "{;", "{<CR>};<Esc>O", { noremap = true })
vim.keymap.set("i", "{,", "{<CR>},<Esc>O", { noremap = true })
vim.keymap.set("i", "[;", "[<CR>];<Esc>O", { noremap = true })
vim.keymap.set("i", "[,", "[<CR>],<Esc>O", { noremap = true })
vim.keymap.set("i", "{<CR>", "{<CR>}<Esc>O", { noremap = true })

-- Have Navigation Keys always center the cursor with zz
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true })
vim.keymap.set("n", "<C-f>", "<C-f>zz", { noremap = true })
vim.keymap.set("n", "<C-b>", "<C-b>zz", { noremap = true })
vim.keymap.set("n", "{", "{zz", { noremap = true })
vim.keymap.set("n", "}", "}zz", { noremap = true })
vim.keymap.set("n", "n", "nzz", { noremap = true })
vim.keymap.set("n", "N", "Nzz", { noremap = true })
vim.keymap.set("n", "[c", "[czz", { noremap = true })
vim.keymap.set("n", "]c", "]czz", { noremap = true })
vim.keymap.set("n", "[m", "[mzz", { noremap = true })
vim.keymap.set("n", "]m", "]mzz", { noremap = true })
vim.keymap.set("n", "[s", "[szz", { noremap = true })
vim.keymap.set("n", "]s", "]szz", { noremap = true })

vim.keymap.set("i", "<C-v>", "<C-r>+", { noremap = true })

-- vim.keymap.set("n", ":", "q:", { noremap = true })
-- vim: ts=2 sts=2 sw=2 et
