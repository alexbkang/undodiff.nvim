local M = {}

-- the active session
local current = nil

function M.is_active(bufnr)
	if not current then
		return false
	end
	for _, b in ipairs(current.buffers) do
		if b == bufnr then
			return true
		end
	end
	return false
end

-- close an undodiff session
function M.close()
	if current == nil then
		return
	end
	local session = current
	current = nil

	-- `:diffoff` restores what `:diffthis` changed.
	if session.source_win and vim.api.nvim_win_is_valid(session.source_win) then
		local cur = vim.api.nvim_get_current_win()
		vim.api.nvim_set_current_win(session.source_win)
		vim.cmd("diffoff")
		vim.api.nvim_set_current_win(cur)
	end
	if session.snapshot_win and vim.api.nvim_win_is_valid(session.snapshot_win) then
		vim.api.nvim_win_close(session.snapshot_win, true)
	end
	if session.tree_win and vim.api.nvim_win_is_valid(session.tree_win) then
		vim.api.nvim_win_close(session.tree_win, true)
	end
end

--- open an undodiff session on the current buffer.
function M.open(opts)
	local source_buf = vim.api.nvim_get_current_buf()

	if M.is_active(source_buf) then
		M.close()
		return
	end

	local filetype = vim.bo[source_buf].filetype
	local snapshot_lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
	local source_win = vim.api.nvim_get_current_win()

	vim.cmd("packadd nvim.undotree")
	local tree_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[tree_buf].bufhidden = "wipe"
	-- pass `winid` so undotree skips `:vnew` which leaks buffers
	-- set nvim_open_win's enter param to false so curr_win doesn't become tree_win
	local tree_win = vim.api.nvim_open_win(tree_buf, false, { split = "left" })
	require("undotree").open({ bufnr = tree_buf, winid = tree_win })

	local snapshot_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[snapshot_buf].bufhidden = "wipe"
	vim.api.nvim_buf_set_lines(snapshot_buf, 0, -1, false, snapshot_lines)
	local snapshot_win = vim.api.nvim_open_win(snapshot_buf, false, { split = "right" })
	vim.api.nvim_win_call(source_win, function()
		vim.cmd("diffthis")
	end)
	vim.api.nvim_win_call(snapshot_win, function()
		vim.cmd("diffthis")
	end)

	-- options
	if opts.treesitter then
		local lang = vim.treesitter.language.get_lang(filetype) or filetype
		if not pcall(vim.treesitter.start, snapshot_buf, lang) then
			vim.bo[snapshot_buf].syntax = filetype
		end
	end

	for _, win in ipairs({ source_win, snapshot_win }) do
		vim.wo[win].number = opts.number
		vim.wo[win].relativenumber = opts.relativenumber
		vim.wo[win].signcolumn = opts.signcolumn
	end

	current = {
		snapshot_win = snapshot_win,
		tree_win = tree_win,
		source_win = source_win,
		source_buf = source_buf,
		buffers = { source_buf, tree_buf, snapshot_buf },
	}

	vim.api.nvim_set_current_win(tree_win)
	return current
end

return M
