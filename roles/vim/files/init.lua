vim.loader.enable()
local api = vim.api

local function initBackground()
	local hour = tonumber(os.date("!%H"))
	if hour > 1 and hour < 10 then
		vim.o.background = "light"
	else
		vim.o.background = "dark"
	end
end

initBackground()
vim.opt.termguicolors = true

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

vim.g.editconfig = true

-- Ollama model configuration — change these two lines to switch models globally
vim.g.ollama_agent_model = "gemma4:12b"           -- used by CopilotChat, avante, codecompanion
vim.g.ollama_complete_model = "qwen2.5-coder:7b" -- used by minuet (inline completion)

vim.g.clipboard = {
	name = "OSC 52",
	copy = {
		["+"] = require("vim.ui.clipboard.osc52").copy("+"),
		["*"] = require("vim.ui.clipboard.osc52").copy("*"),
	},
	paste = {
		["+"] = require("vim.ui.clipboard.osc52").paste("+"),
		["*"] = require("vim.ui.clipboard.osc52").paste("*"),
	},
}

vim.g.mapleader = ","
vim.g.maplocalleader = " "
local function TableConcat(t1, t2)
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i]
	end
	return t1
end

local function SafeRequire(name)
	local ok, mod = pcall(require, name)
	if ok then return mod end
	return setmetatable({}, {
		__index = function(_, _)
			return function() end
		end,
	})
end

local function SafeRequireCallback(name, func)
	local ok, mod = pcall(require, name)
	if ok then func(mod) end
end

local isEmptyTable = function(v)
	return next(v) == nil
end

local langservers = {
	"bashls",
	"dartls",
	"dockerls",
	"efm",
	"emmet_ls",
	"gopls",
	"golangci_lint_ls",
	"graphql",
	"html",
	"jsonls",
	"marksman",
	"pyright",
	"pylsp",
	"rust_analyzer",
	"sqlls",
	"terraformls",
	"ts_ls",
	"vimls",
	"ruff",
	"nushell",
	"fish_lsp",
	"yamlls",
}

if vim.fn.executable("node") == 0 then
	langservers = vim.tbl_filter(function(s)
		return not vim.tbl_contains({ "ts_ls", "html", "jsonls", "graphql", "emmet_ls" }, s)
	end, langservers)
end
if vim.fn.executable("go") == 0 then
	langservers = vim.tbl_filter(function(s)
		return not vim.tbl_contains({ "gopls", "golangci_lint_ls" }, s)
	end, langservers)
end

local function indexOf(array, value)
	for i, v in ipairs(array) do
		if v == value then
			return i
		end
	end
	return nil
end

local function SafeBufGetVar(bufnr, key)
	local ok, value = pcall(vim.api.nvim_buf_get_var, bufnr, key)
	if ok then
		return value, nil
	else
		return nil, value
	end
end

local function termTitle()
	local title = SafeBufGetVar(0, "floaterm_name")
	if title ~= nil then
		return title
	end
	title = api.nvim_buf_get_var(0, "term_title")
	if string.find(title, "term://") ~= nil then
		local start = string.find(title, "//")
		start = string.find(title, ":", start) + 1
		title = title:sub(start, #title)
		if #title > 60 then
			return title:sub(1, 60)
		else
			return title
		end
	else
		local parts = vim.split(title, " ", { trimempty = true })
		parts = { table.unpack(parts, 1, #parts - 1) }
		return table.concat(parts, " ")
	end
end

local lazyPackages = {
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		---@module "ibl"
		---@type ibl.config
		opts = {},
	},
	{ "danymat/neogen", opts = {} },
	{ "SmiteshP/nvim-navic" },
	{ "m-demare/hlargs.nvim" },
	{ "kylechui/nvim-surround", opts = {} },
	{ "numToStr/Comment.nvim", opts = {} },
	{ "nvim-neotest/nvim-nio" },
	{
		"mfussenegger/nvim-dap",
		config = function()
			local dap = require("dap")
			dap.adapters.dart = {
				type = "executable",
				command = "dart",
				args = { "debug_adapter" },
			}
			dap.configurations.dart = {
				{
					type = "dart",
					request = "launch",
					name = "Launch Dart Program",
					program = "${file}",
					cwd = "${workspaceFolder}",
				},
			}
		end,
	},
	{ "mfussenegger/nvim-dap-python" },
	{ "rcarriga/nvim-dap-ui", opts = {} },
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		config = function()
			local lualine = require("lualine")
			local function floatermInfo()
				local bufid = GetTerminalBufnr()
				local buffers = api.nvim_eval("floaterm#buflist#gather()")
				local ret = indexOf(buffers, bufid) .. "/" .. #buffers
				return ret
			end

			local function tab_num()
				return vim.fn.tabpagenr()
			end

			local floaterm_lualine = {
				sections = {
					lualine_a = { "mode", tab_num },
					lualine_b = { "branch", "diff" },
					lualine_c = { "hostname", floatermInfo, termTitle },
					lualine_x = { "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
				inactive_sections = { lualine_c = { floatermInfo }, lualine_z = { "location" } },
				filetypes = { "floaterm" },
			}

			local function getModified()
				if vim.bo.modified then
					return "📖"
				elseif vim.bo.readonly then
					return "🔒"
				else
					return "📗"
				end
			end

			local function GetCurrentDiagnostic()
				local bufnr = 0
				local line_nr = vim.api.nvim_win_get_cursor(0)[1] - 1
				local opts = { ["lnum"] = line_nr }

				local line_diagnostics = vim.diagnostic.get(bufnr, opts)
				if vim.tbl_isempty(line_diagnostics) then
					return
				end

				local best_diagnostic = nil

				for _, diagnostic in ipairs(line_diagnostics) do
					if best_diagnostic == nil or diagnostic.severity < best_diagnostic.severity then
						best_diagnostic = diagnostic
					end
				end

				return best_diagnostic
			end

			local function GetCurrentDiagnosticString()
				local diagnostic = GetCurrentDiagnostic()

				if not diagnostic or not diagnostic.message then
					return
				end

				local message = vim.split(diagnostic.message, "\n")[1]
				local max_width = vim.api.nvim_win_get_width(0) - 35

				if string.len(message) < max_width then
					return message
				else
					return string.sub(message, 1, max_width) .. "..."
				end
			end

			lualine.setup({
				options = {
					theme = "auto",
					section_separators = { "", "" },
					component_separators = { "", "" },
				},
				sections = {
					lualine_a = { "mode", tab_num, { require("minuet.lualine"), display_on_idle = false } },
					lualine_b = {
						{ getModified, color = { fg = "red" } },
						"diagnostics",
						"branch",
						"diff",
					},
					lualine_c = { { floatermInfo, cond = HasTerminal }, { "filename", path = 1 } },
					lualine_x = {
						{
							function()
								return SafeRequire("noice").api.status.mode.get()
							end,
							cond = function()
								local n = SafeRequire("noice")
								return n.api ~= nil and n.api.status.mode.has()
							end,
							color = { fg = "#ff9e64" },
						},
						"encoding",
						"fileformat",
						"filetype",
					},
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
				inactive_sections = {
					lualine_a = { "mode" },
					lualine_b = { { getModified, color = { fg = "red" } } },
					lualine_c = { "filename" },
					lualine_x = { "location" },
					lualine_y = {},
					lualine_z = {},
				},
				extensions = { floaterm_lualine },
			})
		end,
	},
	{ "nvim-lua/plenary.nvim" },
	{
		"nvim-telescope/telescope.nvim",
		event = "VeryLazy",
		dependencies = { "dawsers/telescope-floaterm.nvim" },
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				defaults = {
					mappings = { i = { ["<esc>"] = require("telescope.actions").close } },
				},
			})
			telescope.load_extension("floaterm")
		end,
	},
	{ "windwp/nvim-spectre" },
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"S",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
		},
	},
	{ "MunifTanjim/nui.nvim" },
	{
		"nvim-neo-tree/neo-tree.nvim",
		opts = {
			window = {
				width = 25,
				max_width = 25,
				min_width = 25,
				mappings = {
					["s"] = "none",
				},
			},
			default_component_configs = {
				indent = {
					with_markers = true,
					indent_marker = "│", -- Unicode 直線
					last_indent_marker = "└", -- Unicode L型線
					indent_size = 2,
					padding = 1,
					with_expanders = true,
					expander_collapsed = "▶", -- Unicode 折疊箭頭
					expander_expanded = "▼", -- Unicode 展開箭頭
					expander_highlight = "NeoTreeExpander",
				},
				icon = {
					folder_closed = "📁",
					folder_open = "📂",
					folder_empty = "🗀", -- 或使用 "📁"
					default = "📄", -- 預設檔案圖示
					symlink = "🔗", -- 捷徑圖示
					symlink_arrow = " ➡ ", -- 捷徑箭頭
				},
				modified = {
					symbol = "✏️ ", -- 檔案修改標記
					highlight = "NeoTreeModified",
				},
				name = {
					trailing_slash = false,
					use_git_status_colors = true,
					highlight = "NeoTreeFileName",
				},
				git_status = {
					symbols = {
						-- Git 變更類型
						added = "✚",
						modified = "✹",
						deleted = "✖",
						renamed = "➜",
						-- Git 狀態
						untracked = "❓",
						ignored = "◌",
						unstaged = "☐",
						staged = "☑",
						conflict = "⚠️",
					},
				},
				diagnostics = {
					symbols = {
						hint = "💡",
						info = "ℹ️ ",
						warn = "⚠️ ",
						error = "❌",
					},
				},
			},
		},
	},
	{
		"folke/noice.nvim",
		opts = {
			health = { checker = false },
			messages = {
				enabled = true,
				view = "mini",
				view_error = "notify",
				view_warn = "mini",
				view_history = "messages",
				view_search = "virtualtext",
			},
			notify = { enabled = true },
			lsp = {
				hover = { enabled = true },
				signature = { enabled = false },
				message = { enabled = true },
				progress = { enabled = true },
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
		},
	},
	{ "FabijanZulj/blame.nvim", opts = {} },
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			on_attach = function(bufnr)
				local gs = require("gitsigns")
				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true, desc = desc })
				end
				map("n", "]h", gs.next_hunk, "Next hunk")
				map("n", "[h", gs.prev_hunk, "Prev hunk")
				map("n", "<leader>ghs", gs.stage_hunk, "Stage hunk")
				map("n", "<leader>ghr", gs.reset_hunk, "Reset hunk")
				map("n", "<leader>ghp", gs.preview_hunk, "Preview hunk")
				map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame line (full)")
				map("n", "<leader>ghd", gs.diffthis, "Diff this")
			end,
		},
	},
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = {},
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		opts = { max_lines = 3 },
	},
	{ "folke/which-key.nvim" },
	{ "rcarriga/nvim-notify" },
	{ "Chaitanyabsprip/present.nvim", cmd = { "Present" }, opts = {} },
	{ "mason-org/mason.nvim", opts = {} },
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = { "mason-org/mason.nvim", "hrsh7th/cmp-nvim-lsp" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = vim.tbl_filter(function(server)
					return not vim.tbl_contains({ "dartls", "nushell", "fish_lsp", "gh_actions_ls" }, server)
				end, langservers),
				automatic_installation = false,
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
				filetypes = { "*" },
				root_markers = { ".git" },
			})
			vim.lsp.config("emmet_ls", {
				cmd = { "emmet-language-server", "--stdio" },
				filetypes = { "html", "css", "scss", "javascript", "typescript", "javascriptreact", "typescriptreact" },
				root_markers = { ".git" },
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
				init_options = { command = { "golangci-lint", "run", "--out-format", "json", "--issues-exit-code=1" } },
			})
			vim.lsp.config("graphql", {
				cmd = { "graphql-lsp", "server", "-m", "stream" },
				filetypes = { "graphql", "typescriptreact", "javascriptreact" },
				root_markers = { ".graphqlrc", ".graphqlconfig", ".git" },
			})
			vim.lsp.config("html", {
				cmd = { "vscode-html-language-server", "--stdio" },
				filetypes = { "html" },
				root_markers = { ".git" },
			})
			vim.lsp.config("jsonls", {
				cmd = { "vscode-json-language-server", "--stdio" },
				filetypes = { "json", "jsonc" },
				root_markers = { ".git" },
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
			vim.lsp.config("sqlls", {
				cmd = { "sql-language-server", "up", "--method", "stdio" },
				filetypes = { "sql", "mysql" },
				root_markers = { ".sqllsrc.json", ".git" },
			})
			vim.lsp.config("terraformls", {
				cmd = { "terraform-ls", "serve" },
				filetypes = { "terraform", "tf", "terraform-vars" },
				root_markers = { ".terraform", ".git" },
			})
			vim.lsp.config("ts_ls", {
				cmd = { "typescript-language-server", "--stdio" },
				filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
				root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
			})
			vim.lsp.config("vimls", {
				cmd = { "vim-language-server", "--stdio" },
				filetypes = { "vim" },
				root_markers = { ".git" },
			})
			vim.lsp.config("ruff", {
				cmd = { "ruff", "server" },
				filetypes = { "python" },
				root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
			})
			vim.lsp.config("fish_lsp", {
				cmd = { "fish-lsp", "start" },
				filetypes = { "fish" },
				root_markers = { ".git" },
			})
			if vim.fn.executable("nu") == 1 then
				vim.lsp.config("nushell", {
					cmd = { "nu", "--lsp" },
					filetypes = { "nu" },
					root_markers = { ".git" },
				})
			end

			local capabilities = require("cmp_nvim_lsp").default_capabilities(
				vim.lsp.protocol.make_client_capabilities()
			)
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}
			vim.lsp.config("*", { capabilities = capabilities })
			vim.lsp.enable(langservers)

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufnr = args.buf
					local map = function(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true, desc = desc })
					end
					map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
					map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "LSP code action")
					pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
					vim.api.nvim_create_autocmd("CursorHoldI", {
						buffer = bufnr,
						callback = function()
							pcall(vim.lsp.buf.signature_help)
						end,
					})
				end,
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				["_"] = { "trim_whitespace" },
			},
			format_on_save = {
				-- These options will be passed to conform.format()
				timeout_ms = 500,
				lsp_format = "fallback",
			},
		},
	},
	{ "dstein64/vim-startuptime" },
	{
		"akinsho/git-conflict.nvim",
		config = true,
	},
	{ "kjelly/kube-nvim" },
	{ "voldikss/vim-floaterm" },
	{
		"nat-418/boole.nvim",
		opts = {
			mappings = {
				increment = "<C-a>",
				decrement = "<C-x>",
			},
			additions = {
				{ "Foo", "Bar" },
				{ "tic", "tac", "toe" },
			},
			allow_caps_additions = {
				{ "enable", "disable" },
			},
		},
	},
	{ "unblevable/quick-scope" },
	{ "NvChad/nvim-colorizer.lua", opts = {} },
	{
		"ramilito/kubectl.nvim",
		version = "2.*",
		config = function()
			require("kubectl").setup()
		end,
	},
	{ "junegunn/fzf" },
	{ "ibhagwan/fzf-lua" },
	{
		"otavioschwanck/fzf-lua-enchanted-files",
		dependencies = { "ibhagwan/fzf-lua" },
		config = function()
			-- Modern configuration using vim.g
			vim.g.fzf_lua_enchanted_files = {
				max_history_per_cwd = 50,
			}
		end,
	},
	{ "lambdalisue/suda.vim" },
	{ "ianding1/leetcode.vim" },
	{
		"Mofiqul/vscode.nvim",
		config = function()
			vim.cmd.colorscheme("vscode")
		end,
	},
	{ "m-gail/escape.nvim" },
	{ "rktjmp/lush.nvim" },
	{
		"stevearc/oil.nvim",
		opts = {
			buf_options = { buflisted = true, bufhidden = "unload" },
		},
	},
	{ "tpope/vim-fugitive" },
	{
		"chentoast/marks.nvim",
		opts = {
			default_mappings = true,
			builtin_marks = { ".", "<", ">", "^" },
			cyclic = true,
			force_write_shada = false,
			refresh_interval = 250,
			excluded_filetypes = { "floaterm", "" },
			sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
			bookmark_0 = { sign = "⚑", virt_text = "hello world" },
			mappings = {},
		},
	},
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"hrsh7th/nvim-cmp",
		event = { "InsertEnter" },
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "lukas-reineke/cmp-rg" },
			{ "hrsh7th/cmp-nvim-lsp-document-symbol" },
		},
		config = function()
			local cmp = require("cmp")

			local cmp_sources = {
				{ name = "minuet" },
				{ name = "nvim_lsp", keyword_length = 0 },
				{ name = "path" },
				{
					name = "rg",
					max_item_count = 10,
					keyword_length = 5,
					option = { additional_arguments = "--max-depth 5" },
				},
				{ name = "buffer", keyword_length = 4 },
			}

			if cmp == nil then
				return
			end

			local has_words_before = function()
				if vim.bo[0].buftype == "prompt" then
					return false
				end
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
			end

			cmp.setup({
				preselect = cmp.PreselectMode.None,
				snippet = {
					expand = function(args)
						vim.snippet.expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = {
					["<Space>"] = cmp.mapping(function(fallback)
						if cmp.visible() and cmp.get_active_entry() then
							cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })
						else
							fallback()
						end
					end, { "i", "s", "c" }),
					["<C-d>"] = cmp.mapping.scroll_docs(5),
					["<C-u>"] = cmp.mapping.scroll_docs(-5),
					["<C-g>"] = cmp.mapping(function(fallback)
						if vim.snippet.active({ direction = -1 }) then
							vim.snippet.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
					["<C-f>"] = cmp.mapping(function(fallback)
						if vim.snippet.active({ direction = 1 }) then
							vim.snippet.jump(1)
						elseif has_words_before() then
							cmp.complete()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<m-/>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<C-n>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
						else
							cmp.complete()
						end
					end),
					["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
					["<CR>"] = cmp.mapping(function(fallback)
						if cmp.visible() and cmp.get_active_entry() then
							cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
						else
							fallback()
						end
					end, { "i", "s", "c" }),
				},
				sources = cmp.config.sources(cmp_sources),
				sorting = {
					priority_weight = 2,
					comparators = {
						cmp.config.compare.offset,
						cmp.config.compare.exact,
						cmp.config.compare.score,
						cmp.config.compare.recently_used,
						cmp.config.compare.locality,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
				},
			})

			local search_sources = {
				{ name = "nvim_lsp_document_symbol" },
				{ name = "buffer" },
			}
			local function setup_cmdline(cmd_type, sources)
				cmp.setup.cmdline(cmd_type, {
					mapping = cmp.mapping.preset.cmdline({
						["<C-n>"] = {
							c = function(fallback)
								if cmp.visible() then
									cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
								else
									fallback()
								end
							end,
						},
						["<C-p>"] = {
							c = function(fallback)
								if cmp.visible() then
									cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
								else
									fallback()
								end
							end,
						},
					}),
					view = { entries = { name = "custom", selection_order = "near_cursor" } },
					sources = sources,
				})
			end

			setup_cmdline("/", search_sources)
			setup_cmdline("?", search_sources)

		end,
	},
	{ "windwp/nvim-autopairs", opts = {} },
	{
		"stevearc/aerial.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {},
	},
	{
		"gbrlsnchs/winpick.nvim",
		opts = {
			filter = function(winid, burnr, _)
				local win_info = vim.fn.getwininfo(winid)[1]
				if win_info == nil or win_info.height == nil then
					return false
				end
				if win_info.height < 2 then
					return false
				end
				if #vim.bo[burnr].filetype == 0 then
					return false
				end
				if vim.tbl_contains({ "fidget", "notify" }, vim.bo[burnr].filetype) then
					return false
				end
				return true
			end,
		},
	},
	{
		"mistweaverco/kulala.nvim",
		keys = {
			{ "<leader>Rs", desc = "Send request" },
			{ "<leader>Ra", desc = "Send all requests" },
			{ "<leader>Rb", desc = "Open scratchpad" },
		},
		ft = { "http", "rest" },
		opts = {
			-- your configuration comes here
			global_keymaps = false,
		},
	},
}

if not isEmptyTable(langservers) then
	lazyPackages = TableConcat(lazyPackages, {
		{
			"ravitemer/mcphub.nvim",
			build = "npm install -g mcp-hub@latest",
			config = function()
				require("mcphub").setup()
			end,
		},
		{
			"milanglacier/minuet-ai.nvim",
			config = function()
				require("minuet").setup({
					provider = "openai_fim_compatible",
					n_completions = 1,
					context_window = 1024,
					provider_options = {
						openai_fim_compatible = {
							api_key = "TERM",
							name = "Ollama",
							end_point = "http://localhost:11434/v1/completions",
							model = vim.g.ollama_complete_model,
							optional = {
								max_tokens = 56,
								top_p = 0.9,
							},
						},
					},
					virtualtext = {
						auto_trigger_ft = { "nu", "lua", "python", "helm", "go" },
						keymap = {
							accept = "<tab>",
							accept_line = "<s-tab>",
							prev = "<c-x>k",
							next = "<c-x>j",
						},
					},
				})
			end,
		},
		{
			"yetone/avante.nvim",
			event = "VeryLazy",
			build = "make",
			opts = {
				provider = "gemini",
			},
		},
		{
			"olimorris/codecompanion.nvim",
			event = "VeryLazy",
			opts = {
				strategies = {
					chat = {
						adapter = "copilot",
					},
					inline = {
						adapter = "copilot",
					},
					cmd = {
						adapter = "copilot",
					},
				},
			},
		},
		{
			"arborist-ts/arborist.nvim",
			branch = "main",
		},
		{
			"CopilotC-Nvim/CopilotChat.nvim",
			event = "VeryLazy",
			config = function()
				require("CopilotChat").setup({
					model = vim.g.ollama_agent_model,
					provider = "ollama",
					providers = {
						ollama = {
							prepare_input = require("CopilotChat.config.providers").copilot.prepare_input,
							prepare_output = require("CopilotChat.config.providers").copilot.prepare_output,
							get_headers = function()
								return {}
							end,
							get_url = function()
								return "http://localhost:11434/v1/chat/completions"
							end,
						},
					},
				})
			end,
		},
	})
end

require("lazy").setup(lazyPackages, {})

-- Replace vim-cool: auto-clear hlsearch when not searching in normal mode
vim.on_key(function(char)
	if vim.fn.mode() == "n" then
		vim.opt.hlsearch = vim.tbl_contains({ "n", "N", "*", "#", "?", "/" }, vim.fn.keytrans(char))
	end
end, vim.api.nvim_create_namespace("auto_hlsearch"))

-- Replace persistence.nvim: auto-save/restore session per working directory
local _session_file = vim.fn.stdpath("state") .. "/session.vim"
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		vim.cmd("silent! mksession! " .. _session_file)
	end,
})
vim.keymap.set("n", "<leader>qs", function()
	vim.cmd("source " .. _session_file)
end, { desc = "Restore session" })

vim.cmd.source(vim.fn.stdpath("config") .. "/nvim.vim")

if vim.fn.filereadable("/dev/urandom") then
	function Random(min, max)
		local urandom = assert(io.open("/dev/urandom", "rb"))
		local diff = max - min
		local count = diff / 255 + 1
		local s = urandom:read(count)
		local sum = 0
		for i = 1, count do
			sum = sum + s:byte(i)
		end
		return min + sum % diff
	end
else
	math.randomseed(os.time())
	function Random(min, max)
		return math.floor((math.random(min, max) + math.random(min, max)) / 2)
	end
end

function LinesFrom(file)
	if not FileExists(file) then
		return {}
	end
	local lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
end

function FileBaseName(file)
	return file:match("^.+/(.+)$")
end

function Defer(...)
	local t = 100
	local args = { ... }
	for _, v in ipairs(args) do
		vim.defer_fn(v, t)
		t = t + 10
	end
end

function RandomScheme()
	local schemes = vim.api.nvim_get_runtime_file("colors/*", true)
	local excludedPatterns = { "day", "light" }
	schemes = vim.tbl_filter(function(v)
		if string.find(v, "plugged") == nil then
			return false
		end
		for _, p in ipairs(excludedPatterns) do
			if string.find(v, p) ~= nil then
				return false
			end
		end
		return true
	end, schemes)
	schemes = vim.tbl_map(function(v)
		v = FileBaseName(v)
		for _, p in ipairs(excludedPatterns) do
			if string.find(v, p) ~= nil then
				return nil
			end
		end
		return string.sub(v, 1, #v - 4)
	end, schemes)

	if #schemes > 0 then
		vim.cmd("colorscheme " .. schemes[Random(1, #schemes)])
	end
end

function CheckOutput(command)
	local f = assert(io.popen(command .. " 2>&1", "r"))
	local s = assert(f:read("*a"))
	f:close()
	s = string.gsub(s, "%s+", "")
	return s
end

vim.diagnostic.config({
	virtual_text = {
		source = true,
		severity = { min = vim.diagnostic.severity.INFO },
	},
	float = { source = true },
	update_in_insert = true,
})

function Dump(o)
	print(vim.inspect(o))
end

function FileExists(name)
	local stat = vim.uv.fs_stat(name)
	return stat ~= nil and stat.type == "file"
end


local function smart_dd()
	if vim.api.nvim_get_current_line():match("^%s*$") then
		return '"_dd'
	else
		return "dd"
	end
end

vim.keymap.set("n", "dd", smart_dd, { noremap = true, expr = true })

function ListCurrentBuffer(opts)
	if opts == nil then
		opts = {}
	end
	local lst = vim.fn.getwininfo()
	local ret = {}
	for _, v in pairs(lst) do
		if opts.filetype == nil then
			ret[#ret + 1] = v.bufnr
		else
			if opts.filetype == vim.bo[v.bufnr].filetype then
				ret[#ret + 1] = v.bufnr
			end
		end
	end
	return ret
end

function ListCurrentWindow(opts)
	if opts == nil then
		opts = {}
	end
	local lst = vim.fn.getwininfo()
	local ret = {}
	for _, v in pairs(lst) do
		if opts.filetype == nil then
			ret[#ret + 1] = v.winid
		else
			if opts.filetype == vim.bo[v.bufnr].filetype then
				ret[#ret + 1] = v.winid
			end
		end
	end
	return ret
end

function GlobalFloatermIndex()
	local term_list = ListCurrentBuffer({ filetype = "floaterm" })
	local buffers = api.nvim_eval("floaterm#buflist#gather()")
	if #term_list == 0 then
		return "0/" .. #buffers
	end
	local bufid = term_list[1]
	local ret = indexOf(buffers, bufid) .. "/" .. #buffers
	return ret
end

SafeRequireCallback("notify", function(notify)
	vim.notify = notify
	notify.setup({ background_colour = "#F000000" })
end)

function HasTerminal()
	local ok, buffers = pcall(vim.api.nvim_eval, "floaterm#buflist#gather()")
	if not ok then
		return false
	end
	if #buffers > 0 then
		return true
	end
	return false
end

function GetTerminalBufnr()
	local wininfoTable = vim.fn.getwininfo()
	local tab_num = vim.fn.tabpagenr()

	for _, value in pairs(wininfoTable) do
		if value.terminal > 0 and value.tabnr == tab_num then
			return value.bufnr
		end
	end
	return -1
end

SafeRequireCallback("which-key", function(wk)
	wk.add({
		{ "gr", group = "rename" },
		{ "grr", desc = "rename" },
	})
	wk.add({
		{ "<localleader>d", group = "Debug" },
		{ "<localleader>r", group = "Run" },
	})
	wk.add({
		{ "<leader>a", group = "AnyJump/CocAction" },
		{ "<leader>b", group = "Buffer/Bookmark" },
		{ "<leader>bc", desc = "Copy file path" },
		{ "<leader>c", group = "Comment/cd" },
		{ "<leader>d", group = "doc" },
		{ "<leader>e", group = "Edit" },
		{ "<leader>ecw", desc = "full file" },
		{ "<leader>es", desc = "setting/notes" },
		{ "<leader>f", group = "File/esearch" },
		{ "<leader>g", group = "Git/Paste" },
		{ "<leader>ga", group = "Agit/amend" },
		{ "<leader>gb", group = "blame/branch" },
		{ "<leader>gh", group = "hunk (gitsigns)" },
		{ "<leader>gd", group = "git diff" },
		{ "<leader>gdl", desc = "git diff last commit" },
		{ "<leader>gl", group = "log" },
		{ "<leader>gr", group = "restore" },
		{ "<leader>i", group = "Insert time/Info" },
		{ "<leader>l", group = "Language" },
		{ "<leader>ld", desc = "declaration/definition" },
		{ "<leader>le", desc = "Leetcode" },
		{ "<leader>lr", desc = "Rename/Reference" },
		{ "<leader>ls", desc = "Doc/Workspace Symbol" },
		{ "<leader>lt", desc = "Test" },
		{ "<leader>m", group = "Mark" },
		{ "<leader>mn", desc = "Next mark" },
		{ "<leader>mp", desc = "Previous mark" },
		{ "<leader>n", group = "Note" },
		{ "<leader>o", group = "Fold" },
		{ "<leader>p", group = "Paste/Plugin" },
		{ "<leader>q", group = "Quit" },
		{ "<leader>r", group = "Run/Test" },
		{ "<leader>s", group = "Status" },
		{ "<leader>t", group = "Tab" },
		{ "<leader>v", group = "Gina" },
		{ "<leader>w", group = "Wiki/Window" },
		{ "<leader>wq", desc = "wqa" },
		{ "<leader>ws", desc = "split" },
		{ "<leader>x", group = "Trouble" },
		{ "<leader>z", group = "Grep/Find/FZF" },
	})

	wk.setup({ plugins = { registers = true } })
end)

function MySort(buffer_a, buffer_b)
	local function _sort()
		local a_atime = api.nvim_buf_get_var(buffer_a.id, "atime")
		local b_atime = api.nvim_buf_get_var(buffer_b.id, "atime")
		if a_atime > b_atime then
			return true
		elseif a_atime < b_atime then
			return false
		end
		return buffer_a.id > buffer_b.id
	end

	local ok, retval = pcall(_sort)
	if ok then
		return retval
	else
		return buffer_a.id > buffer_b.id
	end
end

function FindMainWindow()
	local wininfoTable = vim.fn.getwininfo()
	local minMainWidth = 1
	local current_win_id = nil
	local tab_num = vim.fn.tabpagenr()

	for _, value in pairs(wininfoTable) do
		if vim.bo[value.bufnr].filetype == "floaterm" then
		elseif value.tabnr ~= tab_num then
		elseif value.width > minMainWidth then
			minMainWidth = value.width
			current_win_id = value.winid
		end
	end
	return current_win_id
end

function GotoMainWindow()
	local wid = FindMainWindow()
	if wid ~= nil then
		vim.api.nvim_set_current_win(wid)
	end
end

WorkspacePath = vim.env.HOME .. "/vim-notes/"
local function getWorkspaceVimPath(type)
	local function convertName(name)
		local firstChar = string.sub(name, 1, 1)
		local lastChar = string.sub(name, #name, #name)
		local startPos = 1
		local endPos = #name
		if firstChar == "/" then
			startPos = 2
		end
		if lastChar == "/" then
			endPos = #name - 1
		end
		name = string.sub(name, startPos, endPos)
		name = string.gsub(name, "/", "-")
		return name
	end

	local workspace_path = WorkspacePath
	os.execute("mkdir -p " .. workspace_path)
	local workspaceConfigPath = workspace_path .. convertName(vim.fn.getcwd()) .. "." .. type
	return workspaceConfigPath
end
WorkspaceVimPath = getWorkspaceVimPath("vim")

vim.api.nvim_set_keymap("n", "<Leader>esw", "", {
	noremap = true,
	desc = "Edit workspace vim",
	callback = function()
		pcall(EditFile, WorkspaceVimPath)
	end,
})

vim.api.nvim_set_keymap("n", "<Leader>esn", "", {
	noremap = true,
	desc = "Edit workspace note",
	callback = function()
		pcall(EditFile, getWorkspaceVimPath("md"))
	end,
})

vim.api.nvim_set_keymap("n", "<Leader>ess", "", {
	noremap = true,
	desc = "Search the workspace",
	callback = function()
		require("fzf-lua").live_grep({ cwd = WorkspacePath })
	end,
})

function FindFileCwd()
	local cwd = vim.fn.getcwd()
	local currentFile = vim.fn.expand("%:p")
	GotoMainWindow()
	if currentFile ~= "" and string.find(currentFile, cwd) == nil then
		SafeRequire("fzf-lua").files()
		return
	end
	vim.defer_fn(function()
		SafeRequire("fzf-lua-enchanted-files").files()
	end, 100)
end

vim.api.nvim_set_keymap("n", "<c-p>", "", {
	silent = true,
	callback = FindFileCwd,
	desc = "Find file",
})

function FindFileBuffer()
	local oldCwd = vim.fn.getcwd()
	local currentBufferPath = vim.fn.expand("%:p:h")
	GotoMainWindow()
	vim.cmd("cd " .. currentBufferPath)
	SafeRequire("fzf-lua").files()
	vim.cmd("cd " .. oldCwd)
end

vim.api.nvim_set_keymap("", "<leader>zf", "", {
	silent = true,
	callback = FindFileBuffer,
	desc = "Find file in buffer",
})
vim.api.nvim_set_keymap("", "<m-P>", "", {
	silent = true,
	callback = FindFileBuffer,
	desc = "Find file in buffer",
})

local TermIndex = 0
function NewTerminal()
	local name = "t" .. TermIndex
	vim.cmd(string.format("FloatermNew --name=%s --title=%s", name, name))
	TermIndex = TermIndex + 1
end

function TermToggle()
	local bufList = vim.fn.getwininfo()
	local tab_num = vim.fn.tabpagenr()
	for _, v in pairs(bufList) do
		if vim.bo[v.bufnr].filetype == "floaterm" and v.tabnr == tab_num then
			vim.cmd("FloatermHide!")
			return
		end
	end

	Defer(function()
		if vim.bo.filetype ~= "floaterm" then
			GotoMainWindow()
		end
	end, function()
		if HasTerminal() then
			vim.cmd("FloatermShow")
		else
			vim.cmd("FloatermToggle")
		end
	end)
end

function FzfBuffer()
	local filetype = vim.bo.filetype
	if filetype == "floaterm" then
		SafeRequire("telescope._extensions.floaterm.floaterm").search()
	else
		GotoMainWindow()
		if #GetBuffers({}) > 1 then
			SafeRequire("fzf-lua").buffers()
		else
			FindFileCwd()
		end
	end
end

function RunBashCallback(command, callback)
	local Job = require("plenary.job")
	Job:new({
		command = "bash",
		args = { "-c", command },
		on_exit = function(j, exitcode)
			local data = j:result()
			if #data > 0 then
				vim.defer_fn(function()
					callback(j:result(), exitcode)
				end, 100)
			end
		end,
	}):start()
end

function UpdateEnv()
	if vim.fn.filereadable("poetry.lock") > 0 then
		RunBashCallback("poetry run bash -c 'echo $VIRTUAL_ENV' 2>/dev/null", function(data, exitcode)
			vim.env.VIRTUAL_ENV = data[1]
			SafeRequire("dap-python").setup(data[1] .. "/bin/python3")
		end)
		RunBashCallback("poetry run bash -c 'echo $PATH' 2>/dev/null", function(data, exitcode)
			vim.env.PATH = data[1]
			local lst = vim.fn.getcompletion("LspRestart ", "cmdline")
			for _, v in pairs(lst) do
				vim.cmd("LspRestart " .. v)
			end
		end)
	end
end

local function MoveToWindow()
	SafeRequireCallback("winpick", function(winpick)
		local winid = winpick.select()
		if winid then
			vim.api.nvim_set_current_win(winid)
		end
	end)
end

vim.schedule(function()
	SafeRequireCallback("fzf-lua", function(fzf)
		local disable_icons = {
			git_icons = false,
			file_icons = false,
			color_icons = false,
		}
		fzf.setup({
			files = disable_icons,
			buffers = disable_icons,
			grep = disable_icons,
			git = { files = disable_icons },
		})
	end)
	vim.cmd("FzfLua register_ui_select")
	vim.schedule(function()
		vim.api.nvim_create_autocmd("ModeChanged", {
			callback = function()
				if vim.fn.mode() == "n" then
					vim.cmd("setlocal cursorline")
				else
					vim.cmd("setlocal nocursorline")
				end
			end,
		})
		vim.diagnostic.config({ virtual_text = false })
		vim.api.nvim_create_autocmd({ "InsertEnter" }, {
			callback = function()
				vim.diagnostic.config({ virtual_text = false })
			end,
		})
		vim.api.nvim_create_autocmd({ "InsertLeave" }, {
			callback = function()
				vim.diagnostic.config({ virtual_text = true })
			end,
		})

		UpdateEnv()
		if FileExists(WorkspaceVimPath) then
			pcall(vim.api.nvim_command, "source " .. WorkspaceVimPath)
		end

		for _, mode in ipairs({ "i", "n", "t" }) do
			vim.api.nvim_set_keymap(mode, "<m-g>", "", {
				noremap = true,
				desc = "Move to Window",
				callback = MoveToWindow,
			})
		end

	end)
end)

function GetBuffers(opts)
	if opts == nil then
		opts = {}
	end
	local filter = vim.tbl_filter
	local bufnrs = filter(function(b)
		if 1 ~= vim.fn.buflisted(b) then
			return false
		end
		-- only hide unloaded buffers if opts.show_all_buffers is false, keep them listed if true or nil
		if opts.show_all_buffers == false and not vim.api.nvim_buf_is_loaded(b) then
			return false
		end
		if opts.ignore_current_buffer and b == vim.api.nvim_get_current_buf() then
			return false
		end
		if opts.cwd_only and not string.find(vim.api.nvim_buf_get_name(b), vim.uv.cwd(), 1, true) then
			return false
		end
		return true
	end, vim.api.nvim_list_bufs())
	return bufnrs
end

function RunPreviousCommandFunc()
	Defer(function()
		if HasTerminal() == false then
			vim.cmd("FloatermNew")
		end
	end, function()
		local mode = vim.fn.mode()
		if mode == "t" then
			vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<c-c>", true, true, true), "t")
			vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<c-p>", true, true, true), "t")
			vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<cr>", true, true, true), "t")
		elseif mode == "n" then
			Defer(function()
				vim.cmd("FloatermShow")
			end, function()
				vim.fn.feedkeys("i", "t")
				vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<c-p>", true, true, true), "t")
				vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<cr>", true, true, true), "t")
			end)
		elseif mode == "i" then
			Defer(function()
				vim.cmd("stopinsert")
			end, function()
				vim.cmd("FloatermShow")
			end, function()
				vim.fn.feedkeys("i", "t")
				vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<c-p>", true, true, true), "t")
				vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<cr>", true, true, true), "t")
			end)
		end
	end)
end

function RunShellAndShow(command)
	Defer(function()
		if HasTerminal() == false then
			vim.cmd("FloatermNew")
		end
	end, function()
		vim.cmd("FloatermShow")
	end, function()
		vim.cmd("FloatermSend " .. command)
	end)
end

function NextItem(offset)
	local function inner()
		if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
			if offset > 0 then
				vim.cmd("ln")
			else
				vim.cmd("lp")
			end
		elseif vim.api.nvim_eval("len(filter(getwininfo(), 'v:val.quickfix'))") > 0 then
			if offset > 0 then
				vim.cmd("cn")
			else
				vim.cmd("cp")
			end
		else
			vim.cmd("wincmd j")
			if vim.bo.filetype == "Trouble" then
				if offset > 0 then
					vim.cmd("normal j")
				else
					vim.cmd("normal k")
				end
				vim.cmd("wincmd w")
			else
				if offset > 0 then
					vim.diagnostic.jump({ count = 1 })
				else
					vim.diagnostic.jump({ count = -1 })
				end
			end
		end
	end

	pcall(inner)
end

function ToggleMouse()
	vim.o.mouse = vim.o.mouse == "a" and "" or "a"
end

function ToggleStatusLine()
	vim.o.laststatus = vim.o.laststatus == 0 and 2 or 0
end

function ToggleForCopy()
	if not vim.o.number then
		vim.cmd("set nu!")
		vim.cmd("set signcolumn=yes")
	else
		vim.cmd("set nu!")
		vim.cmd("set signcolumn=no")
	end
end

function ResizeWin()
	local screenHeight = vim.o.lines
	if vim.fn.winheight(0) < (screenHeight - 10) then
		vim.cmd("resize " .. screenHeight - 5)
		print("max")
	else
		if vim.fn.winheight(0) >= screenHeight - 3 then
			return
		end

		vim.cmd("resize " .. screenHeight / 2)
		print("equal")
	end
end


function RunInBuffer(command, filename)
	local Job = require("plenary.job")
	local job = Job:new({
		command = "bash",
		args = { "-c", command },
		on_exit = function(j, _)
			vim.defer_fn(function()
				vim.cmd("enew")
				vim.cmd("file! " .. filename .. "-" .. command .. ".log")
				vim.fn.append("$", j:result())
			end, 100)
		end,
	})
	job:start()
end

function GetVisualSelection()
	local s_start = vim.fn.getpos("'<")
	local s_end = vim.fn.getpos("'>")
	local n_lines = math.abs(s_end[2] - s_start[2]) + 1
	local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
	print(vim.inspect(s_start))
	lines[1] = string.sub(lines[1], s_start[3], -1)
	if n_lines == 1 then
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
	else
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
	end
	return table.concat(lines, "\n")
end

function RunBuffer(opts)
	if opts == nil then
		opts = {}
	end
	vim.cmd("set filetype=txt")
	local command = vim.fn.getline(".")
	if opts.select then
		command = GetVisualSelection()
	elseif opts.command then
		command = opts.command
	end
	if opts.new then
		vim.cmd("split")
		vim.cmd("enew")
	end
	local result = vim.fn.searchpos("--- output ---")
	local bufID = vim.fn.bufnr()
	vim.api.nvim_buf_set_name(bufID, command .. "-" .. os.date("%Y-%m-%d-%H-%M-%S") .. ".log")
	if result[1] ~= 0 then
		vim.defer_fn(function()
			vim.cmd(result[1] .. ",$d")
			vim.fn.appendbufline(bufID, "$", "--- output --- processing")
		end, 10)
	else
		vim.fn.appendbufline(bufID, "$", "--- output --- processing")
	end
	local Job = require("plenary.job")
	local job = Job:new({
		command = "bash",
		args = { "-c", command },
		on_stderr = function(_, data)
			vim.defer_fn(function()
				vim.fn.appendbufline(bufID, "$", data)
			end, 100)
		end,
		on_stdout = function(_, data)
			vim.defer_fn(function()
				vim.fn.appendbufline(bufID, "$", data)
			end, 100)
		end,
		on_exit = function(_, exitcode)
			vim.defer_fn(function()
				result = vim.fn.searchpos("--- output ---", "n")
				vim.fn.setbufline(bufID, result[1], string.format("--- output --- [%d]", exitcode))
			end, 100)
		end,
	})

	job:start()
end

function KillAndRerunTerm(name, command, opts)
	if opts == nil then
		opts = { notify = "", autoclose = false, shell = true }
	end
	local notify_command = ""
	if opts.notify ~= "" and opts.notify ~= nil then
		opts.shell = true
		notify_command = string.format(";hterm-notify '%s' '%s'", opts.notify, name)
	end
	local autoclose = 0
	if opts.autoclose then
		autoclose = 1
	end
	local lst = vim.fn.getcompletion("FloatermKill ", "cmdline")
	for _, v in pairs(lst) do
		if v == name then
			vim.cmd("FloatermKill " .. name)
		end
	end
	if opts.shell then
		vim.cmd(
			string.format(
				'FloatermNew --autoclose=%d --name=%s sh -c "%s%s;exit 0"',
				autoclose,
				name,
				command,
				notify_command
			)
		)
	else
		vim.cmd(string.format("FloatermNew --autoclose=%d --name=%s %s", autoclose, name, command, notify_command))
	end
end

function KillAndRerunTermWrapper(command, opts)
	local name = string.gsub(command, " ", "_")
	KillAndRerunTerm(name, command)
	vim.fn.feedkeys("i")
end

function RunCurrentLine()
	local cmd = tostring(vim.api.nvim_get_current_line())
	KillAndRerunTermWrapper(cmd)
end


function EditFile(path)
	GotoMainWindow()
	pcall(vim.cmd, "e " .. path)
end

function FocusNextInputArea()
	local wininfoTable = vim.fn.getwininfo()
	local currentBufnr = vim.api.nvim_win_get_buf(0)
	for _, value in pairs(wininfoTable) do
		if currentBufnr == value.bufnr then
		elseif vim.bo[value.bufnr].modifiable then
			vim.api.nvim_set_current_win(value.winid)
			vim.fn.feedkeys("i")
			return
		elseif vim.bo[value.bufnr].filetype == "floaterm" then
			vim.api.nvim_set_current_win(value.winid)
			vim.fn.feedkeys("i")
			return
		end
	end
end

function UpdateTitleString()
	local hostname = vim.fn.hostname()
	local name = vim.fn.expand("%")
	if vim.bo.filetype == "floaterm" then
		name = vim.fn.escape(termTitle(), "|")
	end
	pcall(vim.cmd, string.format("let &titlestring='%s - %s'", hostname, name))
end

function FloatermNext(offset)
	local current_type = vim.bo.filetype
	if current_type ~= "floaterm" then
		GotoMainWindow()
	end
	if not HasTerminal() then
		vim.cmd("FloatermShow")
	end
	if offset > 0 then
		vim.cmd("FloatermNext")
	else
		vim.cmd("FloatermPrev")
	end
	if vim.fn.mode() == "t" then
		vim.fn.feedkeys("i")
	else
		if current_type == "floaterm" then
		else
			vim.cmd("wincmd w")
		end
	end
end

function RegistersInsert()
	require("fzf-lua").registers({
		actions = {
			["default"] = function(entry)
				local s = entry[1]
				local i = string.find(s, "[", 0, true)
				local j = string.find(s, "]", i, true)
				s = s:sub(i + 1, j - 1)
				vim.fn.feedkeys(string.format('"%sp', s))
			end,
		},
	})
end

function GoToMainWindowAndRunCommand(cmd)
	GotoMainWindow()
	vim.cmd(cmd)
end

function ToggleDark()
	vim.o.background = vim.o.background == "dark" and "light" or "dark"
end

function SendSystemNotification(message)
	local Job = require("plenary.job")
	Job:new({ command = "hterm-notify", args = { "nvim", message } }):start()
end


SafeRequire("nvim-web-devicons").setup({})

vim.g.EINK_WIDTH = vim.env.EINK_WIDTH
local function checkIsEink()
	if vim.g.fullWidth ~= vim.o.columns then
		if tostring(vim.o.columns) == vim.g.EINK_WIDTH then
			vim.schedule(function()
				vim.o.background = "light"
			end)
		else
			vim.schedule(function()
				vim.o.background = "dark"
			end)
		end
		vim.g.fullWidth = vim.o.columns
	end
end
local function updateEinkWidth()
	if vim.env.TMUX == nil then
		vim.schedule(checkIsEink)
	else
		local Job = require("plenary.job")
		local job = Job:new({
			command = "tmux",
			args = { "show-environment", "-g", "EINK_WIDTH" },
			on_stderr = function(_, _) end,
			on_stdout = function(_, data)
				local width = data:gsub("EINK_WIDTH=", ""):gsub("\n", "")
				vim.g.EINK_WIDTH = width
			end,
			on_exit = function(_, _)
				vim.schedule(checkIsEink)
			end,
		})
		job:start()
	end
end

vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		vim.schedule(updateEinkWidth)
	end,
})
vim.schedule(updateEinkWidth)

function StartPueueJob(name, cmd)
	os.execute("pueue group add " .. name)
	os.execute("pueue kill -g " .. name)
	os.execute("pueue clean -g " .. name)
	os.execute("pueue start -g " .. name)

	local Job = require("plenary.job")
	Job:new({
		command = "pueue",
		args = { "add", "-p", "-i", "-g", name, "--", cmd },
		on_exit = function(j, exitcode)
			local data = j:result()
			vim.schedule(function()
				vim.notify(vim.inspect(data))
				vim.cmd(
					string.format("FloatermNew --autoclose=0 --name=%s --title=%s pueue follow %s", name, name, data[1])
				)
			end)
		end,
	}):start()
end

vim.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		local is_tmux = vim.fn.exists("$TMUX") == 1
		local cwd = vim.fn.getcwd()
		if is_tmux then
			vim.opt.titlestring = vim.fn.getcwd() .. " > vim"
		else
			vim.opt.titlestring = "@" .. vim.fn.hostname() .. " " .. "%t"
		end
	end,
})


function SwitchWordCase()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	local word = vim.fn.expand("<cword>")
	local word_start = vim.fn.matchstrpos(vim.fn.getline("."), "\\k*\\%" .. (col + 1) .. "c\\k*")[2]

	-- Detect camelCase
	if word:find("[a-z][A-Z]") then
		-- Convert camelCase to snake_case
		local snake_case_word = word:gsub("([a-z])([A-Z])", "%1_%2"):lower()
		vim.api.nvim_buf_set_text(0, line - 1, word_start, line - 1, word_start + #word, { snake_case_word })
	-- Detect snake_case
	elseif word:find("_[a-z]") then
		-- Convert snake_case to camelCase
		local camel_case_word = word:gsub("(_)([a-z])", function(_, l)
			return l:upper()
		end)
		vim.api.nvim_buf_set_text(0, line - 1, word_start, line - 1, word_start + #word, { camel_case_word })
	else
		print("Not a snake_case or camelCase word")
	end
end

local ns = vim.api.nvim_create_namespace("my.terminal.prompt")
vim.api.nvim_create_autocmd("TermRequest", {
	callback = function(args)
		if string.match(args.data.sequence, "^\027]133;A") then
			local lnum = args.data.cursor[1]
			vim.api.nvim_buf_set_extmark(args.buf, ns, lnum - 1, 0, {
				sign_text = "▶",
				sign_hl_group = "SpecialChar",
			})
		end
	end,
})

local function enableFold()
	vim.o.foldenable = true
	vim.o.foldlevel = 99
	vim.o.foldmethod = "expr"
	vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	vim.o.foldtext = ""
	vim.opt.foldcolumn = "0"
	vim.opt.fillchars:append({ fold = " " })
end
vim.schedule(enableFold)
