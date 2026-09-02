vim.opt.rtp:prepend(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h"))

local plenary_dir = vim.fn.stdpath("cache") .. "/undodiff/plenary.nvim"
if vim.fn.isdirectory(plenary_dir) == 0 then
	vim.fn.system({ "git", "clone", "--depth", "1", "--branch", "v0.1.4",
		"https://github.com/nvim-lua/plenary.nvim", plenary_dir })
end
if vim.fn.isdirectory(plenary_dir) ~= 1 then
	error("plenary.nvim not found; check git/network access")
end
vim.opt.rtp:prepend(plenary_dir)

require("plenary")
