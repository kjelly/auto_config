local parsers = {
	"bash",
	"c",
	"diff",
	"html",
	"javascript",
	"jsdoc",
	"json",
	"lua",
	"luadoc",
	"luap",
	"markdown",
	"markdown_inline",
	"printf",
	"python",
	"query",
	"regex",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"xml",
	"yaml",
	"go",
	"gomod",
	"gowork",
	"dart",
	"rust",
	"hcl",
	"dockerfile",
	"nu",
}

return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = function()
		local ts = require("nvim-treesitter")
		ts.install(parsers):wait(300000)
		ts.update():wait(300000)
	end,
	config = function()
		local ts = require("nvim-treesitter")
		ts.setup({})
		vim.api.nvim_create_user_command("TSInstallConfigured", function()
			ts.install(parsers)
		end, { desc = "Install configured Treesitter parsers" })
		-- Explicit installation avoids network requests on every editor startup.
		local group = vim.api.nvim_create_augroup("ConfigTreesitter", { clear = true })
		vim.api.nvim_create_autocmd("FileType", {
			group = group,
			callback = function(args)
				if vim.bo[args.buf].buftype ~= "" or vim.b[args.buf].snacks_bigfile then
					return
				end
				local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
				local ok, parser = pcall(vim.treesitter.get_parser, args.buf, lang)
				if not lang or not ok or not parser then
					return
				end
				vim.treesitter.start(args.buf, lang)
				vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				vim.wo.foldmethod = "expr"
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.wo.foldlevel = 99
			end,
		})
	end,
}
