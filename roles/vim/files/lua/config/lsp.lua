local langservers = {
	"lua_ls",
	"bashls",
	"dartls",
	"dockerls",
	"efm",
	"gopls",
	"golangci_lint_ls",
	"marksman",
	"pyright",
	"rust_analyzer",
	"terraformls",
	"ts_ls",
	"ruff",
	"nushell",
	"yamlls",
	"tombi",
}

if vim.fn.executable("node") == 0 then
	langservers = vim.tbl_filter(function(s)
		return not vim.tbl_contains({ "bashls", "dockerls", "pyright", "ts_ls", "yamlls" }, s)
	end, langservers)
end
if vim.fn.executable("go") == 0 then
	langservers = vim.tbl_filter(function(s)
		return not vim.tbl_contains({ "gopls", "golangci_lint_ls" }, s)
	end, langservers)
end

return {
	"mason-org/mason-lspconfig.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = { { "mason-org/mason.nvim", opts = {} }, "hrsh7th/cmp-nvim-lsp" },
	config = function()
		require("mason-lspconfig").setup({
			ensure_installed = vim.tbl_filter(function(server)
				return not vim.tbl_contains({ "dartls", "nushell" }, server)
			end, langservers),
			automatic_enable = false,
		})

		-- Ensure external linters/formatters for EFM are installed
		local registry = require("mason-registry")
		local efm_tools = { "hadolint", "shellcheck", "shfmt", "yamllint", "actionlint" }
		for _, name in ipairs(efm_tools) do
			if registry.has_package(name) then
				local p = registry.get_package(name)
				if not p:is_installed() then
					p:install()
				end
			end
		end

		vim.lsp.config("lua_ls", {
			cmd = { "lua-language-server" },
			filetypes = { "lua" },
			root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
			settings = { Lua = { telemetry = { enable = false } } },
		})
		vim.lsp.config("bashls", {
			cmd = { "bash-language-server", "start" },
			filetypes = { "bash", "sh" },
			root_markers = { ".git" },
		})
		vim.lsp.config("dartls", {
			cmd = { "dart", "language-server", "--protocol=lsp" },
			filetypes = { "dart" },
			root_markers = { "pubspec.yaml", ".git" },
		})
		vim.lsp.config("dockerls", {
			cmd = { "docker-langserver", "--stdio" },
			filetypes = { "dockerfile" },
			root_markers = { "Dockerfile", ".git" },
		})
		vim.lsp.config("efm", {
			cmd = { "efm-langserver" },
			filetypes = { "sh", "yaml", "dockerfile", "yaml.github" },
			root_markers = { ".git" },
			init_options = {
				documentFormatting = true,
				documentRangeFormatting = true,
			},
		})
		vim.lsp.config("gopls", {
			cmd = { "gopls" },
			filetypes = { "go", "gomod", "gowork", "gotmpl" },
			root_markers = { "go.work", "go.mod", ".git" },
		})
		vim.lsp.config("golangci_lint_ls", {
			cmd = { "golangci-lint-langserver" },
			filetypes = { "go" },
			root_markers = { "go.mod", ".git" },
			init_options = {
				command = {
					"golangci-lint",
					"run",
					"--output.json.path",
					"stdout",
					"--show-stats=false",
					"--issues-exit-code=1",
				},
			},
		})
		vim.lsp.config("marksman", {
			cmd = { "marksman", "server" },
			filetypes = { "markdown", "markdown.mdx" },
			root_markers = { ".marksman.toml", ".git" },
		})
		vim.lsp.config("pyright", {
			cmd = { "pyright-langserver", "--stdio" },
			filetypes = { "python" },
			root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
		})
		vim.lsp.config("rust_analyzer", {
			cmd = { "rust-analyzer" },
			filetypes = { "rust" },
			root_markers = { "Cargo.toml", ".git" },
		})
		vim.lsp.config("terraformls", {
			cmd = { "terraform-ls", "serve" },
			filetypes = { "terraform", "tf", "terraform-vars", "tofu", "hcl" },
			root_markers = { ".terraform", ".git" },
		})
		vim.lsp.config("tombi", {
			cmd = { "tombi", "lsp" },
			filetypes = { "toml" },
			root_markers = { "tombi.toml", "pyproject.toml", ".git" },
		})
		vim.lsp.config("ts_ls", {
			cmd = { "typescript-language-server", "--stdio" },
			filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
			root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
		})
		vim.lsp.config("ruff", {
			cmd = { "ruff", "server" },
			filetypes = { "python" },
			root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
		})
		if vim.fn.executable("nu") == 1 then
			vim.lsp.config("nushell", {
				cmd = { "nu", "--lsp" },
				filetypes = { "nu" },
				root_markers = { ".git" },
			})
		end

		local capabilities = require("cmp_nvim_lsp").default_capabilities()
		capabilities.textDocument.foldingRange = {
			dynamicRegistration = false,
			lineFoldingOnly = true,
		}
		vim.lsp.config("*", { capabilities = capabilities })
		local group = vim.api.nvim_create_augroup("ConfigLsp", { clear = true })
		vim.api.nvim_create_autocmd("LspAttach", {
			group = group,
			callback = function(args)
				local bufnr = args.buf
				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true, desc = desc })
				end
				map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
				map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "LSP code action")
				pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
				vim.api.nvim_clear_autocmds({ group = group, event = "CursorHoldI", buffer = bufnr })
				vim.api.nvim_create_autocmd("CursorHoldI", {
					group = group,
					buffer = bufnr,
					callback = function()
						for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
							if client:supports_method("textDocument/signatureHelp", bufnr) then
								pcall(vim.lsp.buf.signature_help)
								return
							end
						end
					end,
				})
			end,
		})

		vim.lsp.enable(vim.tbl_filter(function(name)
			local server = vim.lsp.config[name]
			return server and server.cmd and vim.fn.executable(server.cmd[1]) == 1
		end, langservers))
	end,
}
