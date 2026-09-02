local M = {}

local session = require("undodiff.session")

local defaults = {
	treesitter = true,
	number = true,
	relativenumber = false,
	signcolumn = "no",
}

M.opts = vim.deepcopy(defaults)

function M.setup(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

vim.api.nvim_create_user_command("UndodiffToggle", function()
	session.open(M.opts)
end, { desc = "Toggle undodiff" })

return M
