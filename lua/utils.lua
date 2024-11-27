local utils = {}

function utils.map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		if type(opts) == "string" then
			opts = { desc = opts }
		end
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

function utils.nmap(lhs, rhs, opts)
	utils.map("n", lhs, rhs, opts)
end

function utils.imap(lhs, rhs, opts)
	utils.map("i", lhs, rhs, opts)
end

function utils.tmap(lhs, rhs, opts)
	utils.map("t", lhs, rhs, opts)
end

function utils.vmap(lhs, rhs, opts)
	utils.map("v", lhs, rhs, opts)
end

function utils.ternary(cond, T, F, ...)
	if cond then
		return T(...)
	else
		return F(...)
	end
end

return utils
