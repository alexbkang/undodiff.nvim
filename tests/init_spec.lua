local undodiff = require("undodiff")

local defaults = { treesitter = true, number = true, relativenumber = false, signcolumn = "no" }

describe("undodiff init", function()
	before_each(function()
		undodiff.opts = vim.deepcopy(defaults)
	end)

	it("registers :UndodiffToggle without calling setup", function()
		assert.is_true(vim.fn.exists(":UndodiffToggle") == 2)
	end)

	it("applies defaults when setup is not called", function()
		assert.equal(true, undodiff.opts.treesitter)
		assert.equal(true, undodiff.opts.number)
		assert.equal(false, undodiff.opts.relativenumber)
		assert.equal("no", undodiff.opts.signcolumn)
	end)

	it("setup overrides defaults", function()
		undodiff.setup({ number = false })
		assert.equal(false, undodiff.opts.number)
		assert.equal(true, undodiff.opts.treesitter)
	end)

	it("setup merges across multiple calls", function()
		undodiff.setup({ number = false })
		undodiff.setup({ signcolumn = "yes" })
		assert.equal(false, undodiff.opts.number)
		assert.equal("yes", undodiff.opts.signcolumn)
		assert.equal(true, undodiff.opts.treesitter)
	end)
end)
