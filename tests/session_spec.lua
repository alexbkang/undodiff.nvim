local session = require("undodiff.session")

local tmp_files = {}

local function setup_target()
	local tf = vim.fn.tempname() .. ".txt"
	table.insert(tmp_files, tf)
	vim.fn.writefile({ "one", "two", "three" }, tf)
	vim.cmd("edit " .. vim.fn.fnameescape(tf))
	vim.api.nvim_buf_set_lines(0, -1, -1, false, { "four" })
	return tf
end

local function opts()
	return { treesitter = false, number = true, relativenumber = false, signcolumn = "no" }
end

local function cleanup()
	session.close()
	for _, f in ipairs(tmp_files) do
		if vim.fn.filereadable(f) == 1 then
			vim.fn.delete(f)
		end
	end
	tmp_files = {}
end

describe("session", function()
	after_each(cleanup)

	it("open makes is_active true for the source buffer, close restores it", function()
		setup_target()
		local src = vim.api.nvim_get_current_buf()
		assert.is_false(session.is_active(src))
		local s = session.open(opts())
		assert.is_true(session.is_active(src))
		assert.is_true(session.is_active(s.buffers[2]))
		session.close()
		assert.is_false(session.is_active(src))
	end)

	it("is_active is false for a buffer outside any session", function()
		setup_target()
		session.open(opts())
		local unrelated = vim.api.nvim_create_buf(true, false)
		assert.is_false(session.is_active(unrelated))
		vim.api.nvim_buf_delete(unrelated, { force = true })
	end)

	it("close closes the tree and snapshot windows", function()
		setup_target()
		local s = session.open(opts())
		assert.is_true(vim.api.nvim_win_is_valid(s.tree_win))
		assert.is_true(vim.api.nvim_win_is_valid(s.snapshot_win))
		session.close()
		assert.is_false(vim.api.nvim_win_is_valid(s.tree_win))
		assert.is_false(vim.api.nvim_win_is_valid(s.snapshot_win))
	end)

	it("close exits diff mode on the source window", function()
		setup_target()
		local s = session.open(opts())
		assert.is_true(vim.wo[s.source_win].diff)
		session.close()
		assert.is_false(vim.wo[s.source_win].diff)
	end)

	it("puts both diff windows in diff mode", function()
		setup_target()
		local s = session.open(opts())
		assert.is_true(vim.wo[s.source_win].diff)
		assert.is_true(vim.wo[s.snapshot_win].diff)
	end)

	it("applies the window options to both diff windows", function()
		setup_target()
		local s = session.open(opts())
		for _, w in ipairs({ s.source_win, s.snapshot_win }) do
			assert.equal(true, vim.wo[w].number)
			assert.equal(false, vim.wo[w].relativenumber)
			assert.equal("no", vim.wo[w].signcolumn)
		end
	end)

	it("the tree buffer renders undotree entries", function()
		setup_target()
		local s = session.open(opts())
		local lines = vim.api.nvim_buf_get_lines(s.buffers[2], 0, -1, false)
		assert.is_true(#lines > 0)
	end)

	it("the snapshot buffer mirrors the source buffer at open time", function()
		setup_target()
		local src = vim.api.nvim_get_current_buf()
		local src_lines = vim.api.nvim_buf_get_lines(src, 0, -1, false)
		local s = session.open(opts())
		local lines = vim.api.nvim_buf_get_lines(s.buffers[3], 0, -1, false)
		assert.are.same(src_lines, lines)
	end)

	it("the snapshot buffer is not modifiable", function()
		setup_target()
		local s = session.open(opts())
		assert.is_false(vim.bo[s.buffers[3]].modifiable)
	end)

	it("the snapshot window is not focusable", function()
		setup_target()
		local s = session.open(opts())
		assert.is_false(vim.api.nvim_win_get_config(s.snapshot_win).focusable)
	end)

	it("close wipes the tree and snapshot buffers", function()
		setup_target()
		local s = session.open(opts())
		local tree_buf, snapshot_buf = s.buffers[2], s.buffers[3]
		session.close()
		assert.is_false(vim.api.nvim_buf_is_valid(tree_buf))
		assert.is_false(vim.api.nvim_buf_is_valid(snapshot_buf))
	end)

	it("a second open toggles closed instead of stacking", function()
		setup_target()
		local src = vim.api.nvim_get_current_buf()
		session.open(opts())
		local s2 = session.open(opts())
		assert.is_nil(s2)
		assert.is_false(session.is_active(src))
		for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			assert.is_false(vim.wo[w].diff)
		end
	end)

end)
