vim.loader.enable()
local api = vim.api

local function initBackground()
	local ok, s = pcall(vim.fn.system, { "tmux1", "show-environment", "-g", "EINK_WIDTH" })
	if ok then
		local width = tonumber(string.gsub(s, "EINK_WIDTH=", ""), 10)
		if vim.o.columns == width then
			vim.o.background = "light"
		else
			vim.o.background = "dark"
		end
	else
		local hour = tonumber(os.date("!%H"))
		if hour > 1 and hour < 10 then
			vim.o.background = "light"
		else
			vim.o.background = "dark"
		end
	end
end
initBackground()

vim.cmd.source(vim.fn.stdpath("config") .. "/nvim.vim")
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
vim.g.clipboard = "osc52"

vim.g.mapleader = ","
vim.g.maplocalleader = " "
feedback_info = { package_not_found = {} }
function IsModuleAvailable(name)
	if package.loaded[name] then
		return true
	else
		for _, searcher in ipairs(package.loaders) do
			local loader = searcher(name)
			if type(loader) == "function" then
				package.preload[name] = loader
				return true
			end
		end
		return false
	end
end

function Append(t, value)
	t[#t + 1] = value
	return t
end

function TableConcat(t1, t2)
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i]
	end
	return t1
end

local package_loadded = {}
function SafeRequire(name)
	if package_loadded[name] ~= nil then
		return package_loadded[name]
	end
	if IsModuleAvailable(name) then
		package_loadded[name] = require(name)
		return package_loadded[name]
	end
	return setmetatable({}, {
		__index = function(t, key)
			return function()
				Append(feedback_info.package_not_found, name)
			end
		end,
	})
end

function SafeRequireCallback(name, func)
	if package_loadded[name] ~= nil then
		return func(package_loadded[name])
	end

	if IsModuleAvailable(name) then
		package_loadded[name] = require(name)
		return func(package_loadded[name])
	end
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

for _, v in ipairs({ "node", "go" }) do
	if vim.fn.executable(v) == 0 then
		langservers = {}
	end
end

local function indexOf(array, value)
	for i, v in ipairs(array) do
		if v == value then
			return i
		end
	end
	return nil
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
	{ "https://github.com/danymat/neogen", opts = {} },
	{ "mizlan/iswap.nvim", event = "VeryLazy" },
	{ "https://github.com/SmiteshP/nvim-navic" },
	{ "m-demare/hlargs.nvim" },
	{ "https://github.com/kylechui/nvim-surround" },
	{ "https://github.com/smjonas/live-command.nvim" },
	{ "https://github.com/bennypowers/nvim-regexplainer" },
	{
		"kevinhwang91/nvim-hlslens",
		config = function()
			local hlslens = require("hlslens")
			hlslens.setup()
			api.nvim_command(
				"noremap <silent> n <Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>"
			)
			api.nvim_command(
				"noremap <silent> N <Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>"
			)
			api.nvim_command("noremap * *<Cmd>lua require('hlslens').start()<CR>")
			api.nvim_command("noremap # #<Cmd>lua require('hlslens').start()<CR>")
			api.nvim_command("noremap g* g*<Cmd>lua require('hlslens').start()<CR>")
			api.nvim_command("noremap g# g#<Cmd>lua require('hlslens').start()<CR>")
		end,
	},
	{ "https://github.com/nvim-neotest/nvim-nio" },
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
		"https://github.com/nvim-lualine/lualine.nvim",
		config = function()
			local lualine = require("lualine")
			local function showCWD()
				local path = vim.fn.getcwd()
				local home = vim.env.HOME
				path = path:gsub(home, "~")
				return path
			end

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
				if api.nvim_eval("&modified") == 1 then
					return "📖"
				elseif api.nvim_eval("&readonly") == 1 then
					return "🔒"
				else
					return "📗"
				end
			end

			function GetCurrentDiagnostic()
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

			function GetCurrentDiagnosticString()
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
					lualine_a = { "mode", tab_num },
					lualine_b = {
						{ getModified, color = { fg = "red" } },
						"diagnostics",
						"branch",
						"diff",
					},
					lualine_c = { { floatermInfo, cond = HasTerminal }, { "filename", path = 1 } },
					lualine_x = {
						{
							require("noice").api.status.mode.get,
							cond = require("noice") ~= nil and require("noice").api.status.mode.has,
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
	{ "dawsers/telescope-floaterm.nvim" },
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "dawsers/telescope-floaterm.nvim" },
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				pickers = { buffers = { sort_mru = true, ignore_current_buffer = true } },
				defaults = {
					mappings = {
						i = {
							["<esc>"] = require("telescope.actions").close,
							["<cr>"] = fzf_multi_select,
						},
						n = { ["<cr>"] = fzf_multi_select },
					},
				},
			})
			telescope.load_extension("floaterm")
			SafeRequireCallback("telescope.frecency", function(_)
				telescope.load_extension("frecency")
			end)
		end,
	},
	{ "kkharji/sqlite.lua" },
	{ "windwp/nvim-spectre" },
	{
		"https://github.com/yehuohan/hop.nvim",
		opts = {
			winblend = 10,
			jump_on_sole_occurrence = true,
			create_hl_autocmd = true,
			reverse_distribution = false,
		},
	},
	{ "nvim-tree/nvim-web-devicons" },
	{ "MunifTanjim/nui.nvim" },
	{
		"https://github.com/nvim-neo-tree/neo-tree.nvim",
		opts = {
			window = {
				width = 25,
				max_width = 25,
				min_width = 25,
				mappings = {
					["s"] = "none",
				},
			},
		},
	},
	{
		"https://github.com/folke/noice.nvim",
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
	{ "https://github.com/melkster/modicator.nvim", opts = {} },
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		---@module "ibl"
		---@type ibl.config
		opts = {},
	},
	{ "https://github.com/tveskag/nvim-blame-line" },
	{ "https://github.com/numToStr/Comment.nvim" },
	{ "https://github.com/folke/which-key.nvim" },
	{ "https://github.com/romainl/vim-cool" },
	{ "kevinhwang91/promise-async" },
	-- {'https://github.com/kevinhwang91/nvim-ufo'},
	-- {'towolf/vim-helm'},
	{ "rcarriga/nvim-notify" },
	{ "https://github.com/Chaitanyabsprip/present.nvim", opts = {} },
	{ "mason-org/mason.nvim", opts = {} },
	{
		"mason-org/mason-lspconfig.nvim",
		dependencys = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = vim.tbl_filter(function(server)
				return not vim.tbl_contains({ "dartls", "nushell", "fish_lsp", "gh_actions_ls" }, server)
			end, langservers),
			automatic_installation = false,
		},
	},
	{ "neovim/nvim-lspconfig", dependencys = { "williamboman/mason-lspconfig.nvim" } },
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
				lsp_fallback = true,
			},
		},
	},
	{ "https://github.com/dstein64/vim-startuptime" },
	{ "folke/persistence.nvim" },
	-- {'https://github.com/nyngwang/NeoZoom.lua'},
	{
		"https://github.com/akinsho/git-conflict.nvim",
		version = "*",
		config = true,
	},
	{ "https://github.com/kjelly/kube-nvim" },
	{ "voldikss/vim-floaterm" },
	{
		"https://github.com/nat-418/boole.nvim",
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
	{ "https://github.com/NvChad/nvim-colorizer.lua", opts = {} },
	{ "junegunn/fzf" },
	{ "https://github.com/ibhagwan/fzf-lua" },
	{ "lambdalisue/suda.vim" },
	{ "ianding1/leetcode.vim" },
	{
		"https://github.com/Mofiqul/vscode.nvim",
		config = function()
			vim.cmd.colorscheme("vscode")
		end,
	},
	{ "https://github.com/m-gail/escape.nvim" },
	{ "rktjmp/lush.nvim" },
	{
		"https://github.com/stevearc/oil.nvim",
		opts = {
			buf_options = { buflisted = true, bufhidden = "unload" },
		},
	},
	{ "tpope/vim-fugitive" },
	{
		"https://github.com/chentoast/marks.nvim",
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
	{ "hrsh7th/cmp-nvim-lsp", event = { "InsertEnter", "CmdlineEnter" } },
	{ "hrsh7th/cmp-buffer", event = { "InsertEnter", "CmdlineEnter" } },
	{ "hrsh7th/cmp-path", event = { "InsertEnter", "CmdlineEnter" } },
	{ "hrsh7th/cmp-cmdline", event = { "InsertEnter", "CmdlineEnter" } },
	{ "lukas-reineke/cmp-rg", event = { "InsertEnter", "CmdlineEnter" } },
	{ "https://github.com/petertriho/cmp-git", event = { "InsertEnter", "CmdlineEnter" } },
	{ "https://github.com/mtoohey31/cmp-fish", event = { "InsertEnter", "CmdlineEnter" } },
	{ "https://github.com/dmitmel/cmp-cmdline-history", event = { "InsertEnter", "CmdlineEnter" } },
	{ "https://github.com/hrsh7th/cmp-nvim-lsp-document-symbol", event = { "InsertEnter", "CmdlineEnter" } },
	{ "saadparwaiz1/cmp_luasnip", event = { "InsertEnter", "CmdlineEnter" } },
	{ "rafamadriz/friendly-snippets", event = { "InsertEnter", "CmdlineEnter" } },
	{
		"hrsh7th/nvim-cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencys = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "hrsh7th/cmp-cmdline" },
			{ "lukas-reineke/cmp-rg" },
			{ "https://github.com/petertriho/cmp-git" },
			{ "https://github.com/mtoohey31/cmp-fish" },
			{ "https://github.com/dmitmel/cmp-cmdline-history" },
			{ "https://github.com/hrsh7th/cmp-nvim-lsp-document-symbol" },
			{ "saadparwaiz1/cmp_luasnip" },
			{ "rafamadriz/friendly-snippets" },
			{ "neovim/nvim-lspconfig" },
			{ "williamboman/mason-lspconfig.nvim" },
		},
		config = function()
			local cmp = require("cmp")

			local cmp_sources = {
				{ name = "minuet", keyword_length = 0 },
				{ name = "nvim_lsp", keyword_length = 0 },
				{ name = "path" },
				{ name = "luasnip" },
				{
					name = "rg",
					max_item_count = 10,
					keyword_length = 5,
					option = { additional_arguments = "--max-depth 5" },
				},
				{ name = "fish" },
				{ name = "buffer", keyword_length = 4 },
			}
			if vim.fn.executable("node") == 1 then
				table.insert(cmp_sources, { name = "copilot" })
			end

			local source_mapping = {
				buffer = "[Buffer] 📦",
				nvim_lua = "[Lua] 🐖",
				cmp_tabnine = "[TN] 📝",
				path = "[Path] 📁",
				copilot = "[Copilot] ",
				fish = "[fish] 🐠",
				rg = "[rg] 🔎",
				luasnip = "[luasnip] 🐍",
			}

			local has_words_before = function()
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end
			local luasnip = SafeRequire("luasnip")
			if not isEmptyTable(luasnip) then
				require("luasnip.loaders.from_vscode").lazy_load({
					paths = "~/.config/nvim/plugged/friendly-snippets/",
				})
			end
			if cmp == nil then
				return
			end

			local has_words_before = function()
				if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
					return false
				end
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
			end

			SafeRequire("").configure({
				filetypes_denylist = { "dirvish", "fugitive", "floaterm" },
			})

			cmp.setup({
				preselect = cmp.PreselectMode.None,
				snippet = {
					expand = function(args)
						SafeRequire("luasnip").lsp_expand(args.body)
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
						if isEmptyTable(luasnip) then
							fallback()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, {
						"i",
						"s" --[[ "c" (to enable the mapping in command mode) ]],
					}),
					["<C-f>"] = cmp.mapping(function(fallback)
						if isEmptyTable(luasnip) then
							fallback()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						elseif has_words_before() then
							cmp.complete()
						else
							fallback()
						end
					end, {
						"i",
						"s" --[[ "c" (to enable the mapping in command mode) ]],
					}),
					["<m-/>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<C-n>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
						else
							cmp.mapping.complete()
						end
					end),
					["<C-p>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
						else
							cmp.mapping.complete()
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
						-- SafeRequire("copilot_cmp.comparators").prioritize,
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

			SafeRequire("cmp_git").setup()

			-- Set configuration for specific filetype.
			cmp.setup.filetype("gitcommit", {
				sources = cmp.config.sources({
					{ name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
				}, { { name = "buffer" } }),
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

			setup_cmdline(":", {
				{ name = "cmdline", group_index = 1 },
				{ name = "cmdline_history", group_index = 2, max_item_count = 5 },
			})
			setup_cmdline("/", search_sources)
			setup_cmdline("?", search_sources)

			-- Setup lspconfig.
			local capabilities =
				require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}

			-- Use a loop to conveniently call 'setup' on multiple servers and
			-- map buffer local keybindings when the language server attaches
			local lspconfig = require("lspconfig")
			for _, lsp in ipairs(langservers) do
				local on_attach = function(client, bufnr)
					if disabled_lsp_caps[lsp] then
						for _, cap in ipairs(disabled_lsp_caps[lsp]) do
							client.server_capabilities[cap] = false
						end
					end
				end

				lspconfig[lsp].setup({})
			end
		end,
	},
	{
		"ray-x/lsp_signature.nvim",
		event = "InsertEnter",
		opts = {
			bind = true,
			toggle_key = "<a-f>lt",
			select_signature_key = "<a-f>ln",
			timer_interval = 800,
			fix_pos = true,
			floating_window = true,
			max_height = 9,
		},
	},
	{ "https://github.com/windwp/nvim-autopairs" },
	{ "https://github.com/L3MON4D3/LuaSnip", version = "v2.*" },
	{ "https://github.com/gfanto/fzf-lsp.nvim" },
	{
		"https://github.com/stevearc/aerial.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {},
	},
	{
		"https://github.com/gbrlsnchs/winpick.nvim",
		opts = {
			filter = function(winid, burnr, _)
				local win_info = vim.fn.getwininfo(winid)[1]
				if win_info == nil or win_info.height == nil then
					return false
				end
				if win_info.height < 2 then
					return false
				end
				print(vim.bo[burnr].filetype)
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
	{ "mhinz/neovim-remote" },
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
		-- { "https://github.com/zbirenbaum/copilot-cmp", event = { "InsertEnter", "CmdlineEnter" }, opts = {} },
		{ "https://github.com/CopilotC-Nvim/CopilotChat.nvim", event = { "InsertEnter", "CmdlineEnter" }, opts = {} },
		-- {
		-- 	"https://github.com/zbirenbaum/copilot.lua",
		-- 	event = "InsertEnter",
		-- 	opts = {
		-- 		panel = { enabled = true },
		-- 		suggestion = {
		-- 			enabled = true,
		-- 			auto_trigger = true,
		-- 			debounce = 75,
		-- 			keymap = {
		-- 				accept = "<c-x>a",
		-- 				accept_word = "<tab>",
		-- 				accept_line = "<c-x>l",
		-- 				next = "<c-x>n",
		-- 				prev = "<c-x>p",
		-- 				dismiss = "<C-]>",
		-- 			},
		-- 		},
		-- 	},
		-- },
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
					provider = "gemini",
					throttle = 1500,
					virtualtext = {
						auto_trigger_ft = { "nu", "lua", "python", "helm", "go" },
						keymap = {
							accept = "<s-tab>",
							accept_line = "<tab>",
							next = "<a-z>",
						},
					},
				})
			end,
		},
		{
			"https://github.com/yetone/avante.nvim",
			build = "make",
			opts = {
				provider = "gemini",
			},
		},
		{
			"https://github.com/olimorris/codecompanion.nvim",
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
			"nvim-treesitter/nvim-treesitter",
			dependencys = {
				{ "nvim-treesitter/nvim-treesitter-textobjects" },
				{ "nvim-treesitter/nvim-treesitter-refactor" },
				{ "https://github.com/theHamsta/nvim-treesitter-pairs" },
				{ "romgrk/nvim-treesitter-context" },
			},
			config = function()
				local configs = require("nvim-treesitter.configs")
				configs.setup({
					dependencies = { { "nushell/tree-sitter-nu" } },
					ensure_installed = "all",
					autopairs = { enable = true },
					iswap = { enable = true },
					incremental_selection = {
						enable = true,
						keymaps = {
							init_selection = "+",
							node_incremental = "+",
							scope_incremental = "grc",
							node_decremental = "_",
						},
					},
					indent = { enable = false },
					highlight = { enable = true, disable = {} },
					refactor = {
						highlight_definitions = { enable = false },
						highlight_current_scope = { enable = false },
						smart_rename = { enable = true, keymaps = { smart_rename = "grr" } },
						navigation = {
							enable = true,
							keymaps = {
								goto_definition = "gnd",
								list_definitions = "gnD",
								list_definitions_toc = "gO",
								goto_next_usage = "gnu",
								goto_previous_usage = "gnU",
							},
						},
					},
					textobjects = {
						select = {
							enable = true,
							keymaps = {
								["af"] = "@function.outer",
								["if"] = "@function.inner",
								["ac"] = "@class.outer",
								["ic"] = "@class.inner",
								["ao"] = "@block.outer",
								["io"] = "@block.inner",
								["aCa"] = "@call.outer",
								["iCa"] = "@call.inner",
								["aCo"] = "@conditional.outer",
								["iCo"] = "@conditional.inner",
								["aCm"] = "@comment.outer",
								["aF"] = "@frame.outer",
								["iF"] = "@frame.inner",
								["al"] = "@loop.outer",
								["il"] = "@loop.inner",
								["ap"] = "@parameter.outer",
								["ip"] = "@parameter.inner",
								["as"] = "@statement.outer",
								["is"] = "@scopename.inner",
							},
						},
						swap = {
							enable = true,
							swap_next = { ["<leader>lsa"] = "@parameter.inner" },
							swap_previous = { ["<leader>lsA"] = "@parameter.inner" },
						},
						move = {
							enable = true,
							set_jumps = true, -- whether to set jumps in the jumplist
							goto_next_start = { ["]m"] = "@function.outer", ["]]"] = "@class.outer" },
							goto_next_end = { ["]M"] = "@function.outer", ["]["] = "@class.outer" },
							goto_previous_start = {
								["[m"] = "@function.outer",
								["[["] = "@class.outer",
							},
							goto_previous_end = { ["[M"] = "@function.outer", ["[]"] = "@class.outer" },
						},
					},
				})
			end,
		},
		{ "nvim-treesitter/nvim-treesitter-textobjects" },
		{ "nvim-treesitter/nvim-treesitter-refactor" },
		{ "https://github.com/theHamsta/nvim-treesitter-pairs" },
		{ "romgrk/nvim-treesitter-context" },
		{ "https://github.com/David-Kunz/treesitter-unit" },
		{ "https://github.com/nushell/tree-sitter-nu" },
		{ "IndianBoy42/tree-sitter-just" },
	})
end

require("lazy").setup(lazyPackages, {})

vim.cmd.source(vim.fn.stdpath("config") .. "/nvim.vim")

function SafeBufGetVar(bufnr, key)
	local ok, value = pcall(vim.api.nvim_buf_get_var, bufnr, key)
	if ok then
		return value, nil
	else
		return nil, value
	end
end

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
	local uv = vim.loop
	local function file_exists(path)
		local stat = uv.fs_stat(path)
		return stat and stat.type == "file"
	end
end

function DefaultTable(a, b)
	if type(a) == "table" then
		if type(b) == "table" then
			if vim.tbl_count(a) > vim.tbl_count(b) then
				return setmetatable(a, {
					__newindex = function()
						return b
					end,
				})
			else
				return setmetatable(b, {
					__newindex = function()
						return a
					end,
				})
			end
		else
			return setmetatable(a, {
				__newindex = function()
					return b
				end,
			})
		end
	else
		return setmetatable(b, {
			__newindex = function()
				return a
			end,
		})
	end
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
		{ "daC", group = "Call/Comment/Conditional" },
		{ "daCa", desc = "call" },
		{ "daCm", desc = "comment" },
		{ "daCo", desc = "conditional" },
		{ "daF", desc = "frame" },
		{ "dac", desc = "class" },
		{ "daf", desc = "function" },
		{ "dal", desc = "loop" },
		{ "dao", desc = "block" },
		{ "dap", desc = "parameter" },
		{ "das", desc = "scopename" },
		{ "diC", group = "Call/Comment/Conditional" },
		{ "diCa", desc = "call" },
		{ "diCm", desc = "comment" },
		{ "diCo", desc = "conditional" },
		{ "diF", desc = "frame" },
		{ "dic", desc = "class" },
		{ "dif", desc = "function" },
		{ "dil", desc = "loop" },
		{ "dio", desc = "block" },
		{ "dip", desc = "parameter" },
		{ "dis", desc = "scopename" },
		{ "gO", desc = "list_definitions_toc" },
		{ "gn", group = "navigation" },
		{ "gnD", desc = "list_definitions" },
		{ "gnU", desc = "goto_previous_usage" },
		{ "gnd", desc = "goto_definition" },
		{ "gnu", desc = "goto_next_usage" },
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
	local path = vim.loop.cwd() .. "/.git"
	local isGit, _ = vim.loop.fs_stat(path)
	GotoMainWindow()
	if currentFile ~= "" and string.find(currentFile, cwd) == nil then
		SafeRequire("fzf-lua").files()
		return
	end
	local Job = require("plenary.job")

	Job:new({
		command = "bash",
		args = { "-c", "git rev-parse --is-inside-work-tree" },
		on_exit = function(_, exitcode)
			if exitcode == 0 then
				vim.defer_fn(function()
					SafeRequire("fzf-lua").git_files()
				end, 100)
			else
				vim.defer_fn(function()
					SafeRequire("fzf-lua").files()
				end, 100)
			end
		end,
	}):start()
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
	local filetype = vim.api.nvim_eval("&filetype")
	local fzf = require("fzf-lua")
	if filetype == "floaterm" then
		SafeRequire("telescope._extensions.floaterm.floaterm").search()
	else
		GotoMainWindow()
		if #GetBuffers({}) > 1 then
			SafeRequire("telescope.builtin").buffers()
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

local function SetupFileType()
	vim.filetype.add({
		pattern = {
			[".*/templates/.*yaml"] = "helm",
			[".*/templates/.*yml"] = "helm",
			["_helpers.tpl"] = "helm",
		},
	})
end

function DelaySetup2()
	SetupFileType()
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

	function MoveToWindow()
		SafeRequireCallback("winpick", function(winpick)
			local winid = winpick.select()
			if winid then
				vim.api.nvim_set_current_win(winid)
			end
		end)
	end

	vim.api.nvim_set_keymap("i", "<m-g>", "", {
		noremap = true,
		desc = "Move to Window",
		callback = MoveToWindow,
	})

	vim.api.nvim_set_keymap("n", "<m-g>", "", {
		noremap = true,
		desc = "Move to Window",
		callback = MoveToWindow,
	})

	vim.api.nvim_set_keymap("t", "<m-g>", "", {
		noremap = true,
		desc = "Move to Window",
		callback = MoveToWindow,
	})

	SafeRequire("copilot_cmp").setup({ method = "getCompletionsCycling" })
end

function DelaySetup1()
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
	vim.schedule(DelaySetup2)
end

vim.schedule(DelaySetup1)

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
		if opts.cwd_only and not string.find(vim.api.nvim_buf_get_name(b), vim.loop.cwd(), 1, true) then
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
			if vim.api.nvim_eval("&filetype") == "Trouble" then
				if offset > 0 then
					vim.cmd("normal j")
				else
					vim.cmd("normal k")
				end
				vim.cmd("wincmd w")
			else
				if offset > 0 then
					vim.diagnostic.goto_next()
				else
					vim.diagnostic.goto_prev()
				end
			end
		end
	end

	pcall(inner)
end

function ToggleMouse()
	if vim.api.nvim_eval("&mouse") == "a" then
		vim.cmd("set mouse=")
	else
		vim.cmd("set mouse=a")
	end
end

function ToggleStatusLine()
	if vim.api.nvim_eval("&laststatus") == 0 then
		vim.cmd("set laststatus=2")
	else
		vim.cmd("set laststatus=0")
	end
end

function ToggleForCopy()
	if vim.api.nvim_eval("&nu") == 0 then
		vim.cmd("set nu!")
		vim.cmd("set signcolumn=yes")
	else
		vim.cmd("set nu!")
		vim.cmd("set signcolumn=no")
	end
end

function ResizeWin()
	local screenHeight = vim.api.nvim_eval("&lines")
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

function SSH(command, hosts)
	local Job = require("plenary.job")

	for _, v in pairs(hosts) do
		local job = Job:new({
			command = "ssh",
			args = { "v1", "-t", command },
			cwd = "/usr/bin",
			env = { ["a"] = "b" },
		})
		job:start()
		job:after_success(function()
			vim.defer_fn(function()
				vim.cmd("enew")
				vim.cmd("file! " .. v .. "-" .. command .. ".log")
				vim.fn.append("$", job:result())
			end, 100)
		end)
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
	if opts.notify ~= "" or opts.notify ~= nil then
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
	vim.fn.feedkeys("i")
end

function UpdatePlug()
	local scan = require("plenary.scandir")
	local Job = require("plenary.job")
	local all_dir =
		scan.scan_dir(vim.fn.expand("$HOME/.config/nvim/plugged/"), { hidden = false, depth = 1, only_dirs = true })
	local total = #all_dir
	local count = 0

	for _, v in pairs(all_dir) do
		Job:new({
			command = "bash",
			args = { "-c", string.format("cd %s;git pull;git gc --prune=all", v) },
			on_exit = function(j, return_val)
				if return_val ~= 0 then
					SafeRequireCallback("notify", function(notify)
						notify(
							"pull failed," .. v,
							vim.log.levels.ERROR,
							{ title = "error to update plugin", hide_from_history = true }
						)
					end)
				end
				count = count + 1
				if count % 50 == 0 or count == total then
					SafeRequireCallback("notify", function(notify)
						notify(
							count .. "-" .. total,
							vim.log.levels.INFO,
							{ title = "update", hide_from_history = true }
						)
					end)
				end
			end,
		}):start()
	end
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
	if vim.api.nvim_eval("&filetype") == "floaterm" then
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
	if vim.o.background == "dark" then
		vim.o.background = "light"
	else
		vim.o.background = "dark"
	end
end

function SendSystemNotification(message)
	local Job = require("plenary.job")
	Job:new({ command = "hterm-notify", args = { "nvim", message } }):start()
end

function HookPwdChanged(after, before) end

SafeRequire("nvim-web-devicons").setup({})

vim.g.EINK_WIDTH = 0
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

if vim.fn.executable("tmux") == 1 then
	vim.api.nvim_create_autocmd("VimResized", {
		callback = function()
			vim.schedule(updateEinkWidth)
		end,
	})
	vim.schedule(updateEinkWidth)
end

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

if vim.fn.executable("nu") == 1 then
	local lsp = require("lspconfig")
	vim.tbl_deep_extend("keep", lsp, {
		nushell = { cmd = { "nu", "--lsp" }, filetypes = "nu", name = "nushell" },
	})
	lsp.nushell.setup({})
end

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

vim.api.nvim_create_autocmd("TermOpen", { command = "setlocal signcolumn=auto" })
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
