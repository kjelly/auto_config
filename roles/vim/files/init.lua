vim.loader.enable()
local api = vim.api

local function initBackground()
	if vim.env.LC_IS_EINK == "1" or vim.env.LC_IS_EINK == "true" then
		vim.o.background = "light"
		return
	end
	if vim.env.COLORFGBG and vim.env.COLORFGBG:sub(1, 3) == "15;" then
		vim.o.background = "light"
		return
	end
	local hour = tonumber(os.date("!%H"))
	if hour > 1 and hour < 10 then
		vim.o.background = "light"
	else
		vim.o.background = "dark"
	end
end

initBackground()
vim.opt.termguicolors = true
vim.opt.guicursor = "a:block-blinkon0" -- Disable cursor blinking for E-ink

local function setTransparentBackground()
	local hl_groups = { "Normal", "NormalFloat", "SignColumn", "LineNr", "Folded", "NonText", "NormalNC" }
	for _, group in ipairs(hl_groups) do
		vim.api.nvim_set_hl(0, group, { bg = "NONE" })
	end
	if vim.env.LC_IS_EINK == "1" or vim.env.LC_IS_EINK == "true" or vim.o.background == "light" then
		vim.api.nvim_set_hl(0, "Comment", { fg = "#333333", italic = true, bold = true })
		vim.api.nvim_set_hl(0, "LineNr", { fg = "#444444", bold = true })
	end
end

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter", "UIEnter" }, {
	pattern = "*",
	callback = function()
		vim.schedule(setTransparentBackground)
	end,
})

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
-- Autocomplete engine choice: "cmp" or "blink"
vim.g.completion_engine = "blink"

-- Ollama model configuration — change this line to switch the local chat model globally
vim.g.ollama_agent_model = "gemma4:12b" -- used by CopilotChat and CodeCompanion

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
	if ok then
		return mod
	end
	return setmetatable({}, {
		__index = function(_, _)
			return function() end
		end,
	})
end

local function SafeRequireCallback(name, func)
	local ok, mod = pcall(require, name)
	if ok then
		func(mod)
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
}

if vim.fn.executable("node") == 0 then
	langservers = vim.tbl_filter(function(s)
		return s ~= "ts_ls"
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

local term_bufs = {}
local last_active_idx = 1
local term_names = {}

local function get_term_win_in_tab()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].buftype == "terminal" then
			return win, buf
		end
	end
	return nil, nil
end

local function get_valid_term_bufs()
	local valid = {}
	for _, buf in ipairs(term_bufs) do
		if vim.api.nvim_buf_is_valid(buf) then
			table.insert(valid, buf)
		end
	end
	term_bufs = valid
	return valid
end

local function setup_terminal_buffer(bufnr, name)
	term_names[bufnr] = name
	vim.api.nvim_buf_set_var(bufnr, "floaterm_name", name)
	vim.bo[bufnr].filetype = "terminal"
end

local function get_term_by_name(name)
	for buf, n in pairs(term_names) do
		if n == name and vim.api.nvim_buf_is_valid(buf) then
			return buf
		end
	end
	return nil
end

function NativeTermSendTrimmed(mode)
	local lines = {}
	if mode == "v" then
		local start_line = vim.fn.getpos("'<")[2]
		local end_line = vim.fn.getpos("'>")[2]
		lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	elseif mode == "a" then
		lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	else
		lines = { vim.api.nvim_get_current_line() }
	end

	local trimmed = {}
	for _, line in ipairs(lines) do
		table.insert(trimmed, vim.trim(line))
	end

	local win, buf = get_term_win_in_tab()
	if not win then
		TermToggle()
		win, buf = get_term_win_in_tab()
	end

	if win and buf then
		local chan = vim.bo[buf].channel
		vim.api.nvim_chan_send(chan, table.concat(trimmed, "\r") .. "\r")
	end
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

package.preload["oil_buf_history"] = function()
	local M = {}
	M.stack = {}

	local function is_oil_buf(b)
		if not vim.api.nvim_buf_is_valid(b) then
			return false
		end
		local ok, ft = pcall(vim.api.nvim_get_option_value, "filetype", { buf = b })
		if ok and ft == "oil" then
			return true
		end
		local name = vim.api.nvim_buf_get_name(b)
		return name:match("^oil://")
			or name:match("^oil%-ssh://")
			or name:match("^oil%-s3://")
			or name:match("^oil%-sss://")
			or name:match("^oil%-trash://")
	end

	local function push(b)
		for i = #M.stack, 1, -1 do
			if M.stack[i] == b then
				table.remove(M.stack, i)
			end
		end
		if M.stack[#M.stack] == b then
			return
		end
		table.insert(M.stack, b)
		if #M.stack > 50 then
			table.remove(M.stack, 1)
		end
	end

	function M.record_for_buf(b)
		if is_oil_buf(b) then
			push(b)
		end
	end

	function M.back()
		local current = vim.api.nvim_get_current_buf()
		for i = #M.stack, 1, -1 do
			if M.stack[i] == current then
				table.remove(M.stack, i)
			end
		end
		while #M.stack > 0 do
			local b = table.remove(M.stack)
			if vim.api.nvim_buf_is_valid(b) and is_oil_buf(b) then
				local opened = false
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_get_buf(win) == b then
						vim.api.nvim_set_current_win(win)
						opened = true
						break
					end
				end
				if not opened then
					vim.cmd.split()
					vim.api.nvim_win_set_buf(0, b)
				end
				return
			end
		end
		vim.notify("Oil: no previous oil buffer", vim.log.levels.INFO)
	end

	return M
end

package.preload["blink_cmdline_history"] = function()
	local source = {}

	function source.new(opts)
		return setmetatable({ opts = opts or {} }, { __index = source })
	end

	function source:enabled()
		local t = vim.fn.getcmdtype()
		return t == ":" or t == "/" or t == "?" or t == "@"
	end

	function source:get_completions(ctx, callback)
		local t = vim.fn.getcmdtype()
		local hname = (t == ":" or t == "@") and "cmd" or "search"
		local count = vim.fn.histnr(hname)
		local limit = 200
		local seen, items = {}, {}
		local from = math.max(1, count - limit + 1)
		for i = count, from, -1 do
			local entry = vim.fn.histget(hname, i)
			if entry and entry ~= "" and not seen[entry] then
				seen[entry] = true
				items[#items + 1] = {
					label = entry,
					filterText = entry,
					sortText = string.format("%06d", count - i),
					insertText = entry,
					kind = require("blink.cmp.types").CompletionItemKind.Snippet,
					labelDetails = { description = "history" },
				}
			end
		end
		callback({ items = items, is_incomplete_backward = false, is_incomplete_forward = false })
	end

	return source
end

local lazyPackages = {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			bigfile = { enabled = true },
			dashboard = { enabled = true },
			indent = { enabled = true },
			input = { enabled = true },
			notifier = { enabled = true },
			picker = { enabled = true },
			quickfile = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = false },
			words = { enabled = true },
		},
		keys = {
			{
				"<leader>.",
				function()
					require("snacks").scratch()
				end,
				desc = "Toggle Scratch Buffer",
			},
			{
				"<leader>S",
				function()
					require("snacks").scratch.select()
				end,
				desc = "Select Scratch Buffer",
			},
			{
				"<leader>un",
				function()
					require("snacks").notifier.hide()
				end,
				desc = "Dismiss All Notifications",
			},
			{
				"<leader>nh",
				function()
					require("snacks").notifier.show_history()
				end,
				desc = "Notification History",
			},
			{
				"]]",
				function()
					require("snacks").words.jump(vim.v.count1)
				end,
				desc = "Next Reference",
				mode = { "n", "t" },
			},
			{
				"[[",
				function()
					require("snacks").words.jump(-vim.v.count1)
				end,
				desc = "Prev Reference",
				mode = { "n", "t" },
			},
		},
	},
	{ "danymat/neogen", opts = {} },
	{ "SmiteshP/nvim-navic" },
	{ "m-demare/hlargs.nvim" },
	{ "kylechui/nvim-surround", opts = {} },
	{ "nvim-neotest/nvim-nio", lazy = true },
	{
		"mfussenegger/nvim-dap",
		lazy = true,
		keys = { "<localleader>dc", "<localleader>dt", "<localleader>di", "<localleader>do", "<localleader>dr" },
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
	{ "mfussenegger/nvim-dap-python", lazy = true },
	{ "rcarriga/nvim-dap-ui", lazy = true, keys = { "<localleader>du" }, opts = {} },
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		config = function()
			local lualine = require("lualine")
			local function floatermInfo()
				local win, buf = get_term_win_in_tab()
				if not buf then
					return ""
				end
				local valid = get_valid_term_bufs()
				local idx = indexOf(valid, buf) or 0
				return idx .. "/" .. #valid
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
				filetypes = { "terminal" },
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
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				defaults = {
					mappings = { i = { ["<esc>"] = require("telescope.actions").close } },
				},
			})
		end,
	},
	{
		"MagicDuck/grug-far.nvim",
		cmd = { "GrugFar" },
		keys = {
			{
				"<leader>zR",
				function()
					require("grug-far").open()
				end,
				mode = { "n", "x" },
				desc = "Search and Replace (GrugFar)",
			},
		},
		opts = {},
	},
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
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
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
				map("n", "<leader>ghb", function()
					gs.blame_line({ full = true })
				end, "Blame line (full)")
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
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")
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
				{ "<leader>u", group = "UI" },
				{ "<leader>v", group = "Gina" },
				{ "<leader>w", group = "Wiki/Window" },
				{ "<leader>wq", desc = "wqa" },
				{ "<leader>ws", desc = "split" },
				{ "<leader>x", group = "Trouble" },
				{ "<leader>z", group = "Grep/Find/FZF" },
			})
			wk.setup({ plugins = { registers = true } })
		end,
	},
	{ "Chaitanyabsprip/present.nvim", cmd = { "Present" }, opts = {} },
	{ "mason-org/mason.nvim", opts = {} },
	{
		"mason-org/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = (function()
			if vim.g.completion_engine == "blink" then
				return { "mason-org/mason.nvim", "saghen/blink.cmp" }
			else
				return { "mason-org/mason.nvim", "hrsh7th/cmp-nvim-lsp" }
			end
		end)(),
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = vim.tbl_filter(function(server)
					return not vim.tbl_contains({ "dartls", "nushell" }, server)
				end, langservers),
				automatic_installation = false,
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

			local capabilities
			if vim.g.completion_engine == "blink" then
				capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())
			else
				capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
			end
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
		event = { "BufReadPost", "BufWritePre" },
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				go = { "goimports", "gofmt" },
				json = { "prettierd", "prettier", stop_after_first = true },
				yaml = { "prettierd", "prettier", stop_after_first = true },
				["yaml.github"] = { "prettierd", "prettier", stop_after_first = true },
				terraform = { "tofu_fmt", "terraform_fmt", stop_after_first = true },
				hcl = { "tofu_fmt" },
				sh = { "shfmt" },
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

	{
		"nat-418/boole.nvim",
		lazy = true,
		keys = { "<C-a>", "<C-x>", "<leader>st" },
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
	{ "unblevable/quick-scope", lazy = true, event = "BufReadPost" },
	{ "NvChad/nvim-colorizer.lua", lazy = true, event = "BufReadPost", opts = {} },
	{
		"ramilito/kubectl.nvim",
		lazy = true,
		cmd = "Kubectl",
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
			vim.cmd.colorscheme("vscode-eink")
		end,
	},
	{ "m-gail/escape.nvim" },
	{ "rktjmp/lush.nvim" },
	{
		"stevearc/oil.nvim",
		lazy = false,
		opts = {
			cleanup_delay_ms = false,
			buf_options = { buflisted = true, bufhidden = "hide" },
			view_options = {
				sort = {
					{ "type", "asc" },
					{ "name", "asc" },
				},
				show_hidden = false,
			},
			keymaps = {
				["<BS>"] = function()
					local cur_name = vim.api.nvim_buf_get_name(0)
					if not cur_name:match("^oil://") then
						return
					end
					local path = cur_name:gsub("^oil://", ""):gsub("/$", "")
					if path == "" then
						return
					end
					local parent
					if path == "/" then
						parent = "/"
					else
						parent = vim.fn.fnamemodify(path, ":h")
					end
					OilReuseBuf(parent)
				end,
				["<CR>"] = function()
					local entry = require("oil").get_cursor_entry()
					if not entry then
						return
					end
					local cur_name = vim.api.nvim_buf_get_name(0)
					if not cur_name:match("^oil://") then
						return
					end
					local cur_dir = cur_name:gsub("^oil://", ""):gsub("/$", "")
					local target = cur_dir .. "/" .. entry.name
					local stat = vim.uv.fs_stat(target)
					if not stat then
						return
					end
					if stat.type == "directory" then
						OilReuseBuf(target)
					else
						require("oil.actions").select.callback()
					end
				end,
				["-"] = function()
					local cur_name = vim.api.nvim_buf_get_name(0)
					if not cur_name:match("^oil://") then
						return
					end
					local path = cur_name:gsub("^oil://", ""):gsub("/$", "")
					if path == "" then
						return
					end
					local parent
					if path == "/" then
						parent = "/"
					else
						parent = vim.fn.fnamemodify(path, ":h")
					end
					OilReuseBuf(parent)
				end,
				["_"] = function()
					OilReuseBuf(vim.fn.getcwd())
				end,
				["`"] = function()
					local cur_name = vim.api.nvim_buf_get_name(0)
					if not cur_name:match("^oil://") then
						return
					end
					local path = cur_name:gsub("^oil://", ""):gsub("/$", "")
					if path == "" or path == "/" then
						return
					end
					OilReuseBuf(path)
					vim.cmd.cd(path)
				end,
			},
		},
	},
	{ "tpope/vim-fugitive" },
	{
		"chentoast/marks.nvim",
		lazy = true,
		event = "BufReadPost",
		opts = {
			default_mappings = true,
			builtin_marks = { ".", "<", ">", "^" },
			cyclic = true,
			force_write_shada = false,
			refresh_interval = 250,
			excluded_filetypes = { "terminal", "" },
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
		enabled = function()
			return vim.g.completion_engine == "cmp"
		end,
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "lukas-reineke/cmp-rg" },
			{ "hrsh7th/cmp-nvim-lsp-document-symbol" },
			{ "hrsh7th/cmp-cmdline" },
		},
		config = function()
			local cmp = require("cmp")

			local cmp_sources = {
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
				completion = {
					preselect = false,
				},
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
							cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
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
						["<Down>"] = {
							c = function(fallback)
								if cmp.visible() then
									cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
								else
									fallback()
								end
							end,
						},
						["<Up>"] = {
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
			setup_cmdline(":", {
				{ name = "path" },
				{ name = "cmdline" },
			})
		end,
	},
	{ "windwp/nvim-autopairs", opts = {} },
	{
		"nvim-tree/nvim-web-devicons",
		opts = {
			default = true,
			default_icon = {
				icon = "📄",
				color = "#6d8086",
				name = "Default",
			},
		},
		config = function(_, opts)
			local devicons = require("nvim-web-devicons")
			devicons.setup(opts)

			local is_pua = function(char)
				if not char or char == "" then
					return false
				end
				local cp = vim.fn.char2nr(char)
				return (cp >= 57344 and cp <= 63743)
					or (cp >= 983040 and cp <= 1048575)
					or (cp >= 1048576 and cp <= 1114111)
			end

			local emoji_extensions = {
				py = "🐍",
				go = "🐹",
				lua = "🌙",
				c = "⚙️",
				h = "⚙️",
				cpp = "🛠️",
				hpp = "🛠️",
				cc = "🛠️",
				cxx = "🛠️",
				rs = "🦀",
				js = "📜",
				ts = "📘",
				jsx = "⚛️",
				tsx = "⚛️",
				html = "🌐",
				css = "🎨",
				scss = "🎨",
				sh = "🐚",
				bash = "🐚",
				zsh = "🐚",
				fish = "🐚",
				json = "📦",
				yaml = "⚙️",
				yml = "⚙️",
				toml = "🔧",
				ini = "📝",
				conf = "📝",
				sql = "🗄️",
				db = "🗄️",
				tf = "🧱",
				txt = "📄",
				md = "📝",
				markdown = "📝",
				zip = "🤐",
				tar = "🤐",
				gz = "🤐",
				xz = "🤐",
				rar = "🤐",
				["7z"] = "🤐",
				pdf = "📕",
				png = "🖼️",
				jpg = "🖼️",
				jpeg = "🖼️",
				gif = "🖼️",
				svg = "🖼️",
				webp = "🖼️",
				bmp = "🖼️",
				ico = "🖼️",
				mp3 = "🎵",
				wav = "🎵",
				flac = "🎵",
				ogg = "🎵",
				m4a = "🎵",
				mp4 = "🎥",
				mkv = "🎥",
				avi = "🎥",
				mov = "🎥",
				webm = "🎥",
				log = "📋",
				java = "☕",
				class = "☕",
				jar = "☕",
				php = "🐘",
				rb = "💎",
				swift = "🐦",
				kt = "🎯",
				kts = "🎯",
				pl = "🐪",
				pm = "🐪",
				r = "📊",
			}

			local emoji_filenames = {
				[".gitignore"] = "🐙",
				[".gitconfig"] = "🐙",
				[".gitattributes"] = "🐙",
				["Makefile"] = "🛠️",
				["makefile"] = "🛠️",
				["justfile"] = "🛠️",
				["Dockerfile"] = "🐳",
				["dockerfile"] = "🐳",
				["docker-compose.yml"] = "🐳",
				["docker-compose.yaml"] = "🐳",
				["LICENSE"] = "📜",
				["README.md"] = "📝",
			}

			local ext_icons = devicons.get_icons()
			for ext, emoji in pairs(emoji_extensions) do
				if ext_icons[ext] then
					ext_icons[ext].icon = emoji
				else
					ext_icons[ext] = { icon = emoji, name = ext }
				end
			end

			local fn_icons = devicons.get_icons_by_filename()
			for fn, emoji in pairs(emoji_filenames) do
				if fn_icons[fn] then
					fn_icons[fn].icon = emoji
				else
					fn_icons[fn] = { icon = emoji, name = fn }
				end
			end

			for _, info in pairs(ext_icons) do
				if is_pua(info.icon) then
					info.icon = "📄"
				end
			end
			for _, info in pairs(fn_icons) do
				if is_pua(info.icon) then
					info.icon = "📄"
				end
			end

			devicons.set_up_highlights()
		end,
	},
	{
		"stevearc/aerial.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {},
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
	{
		"echasnovski/mini.indentscope",
		version = false,
		event = "BufReadPost",
		opts = {
			symbol = "│",
			options = { try_as_border = true },
		},
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = {
					"help",
					"alpha",
					"dashboard",
					"neo-tree",
					"Trouble",
					"lazy",
					"mason",
					"notify",
					"toggleterm",
					"lazyterm",
				},
				callback = function()
					vim.b.miniindentscope_disable = true
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			highlight = { enable = true },
			indent = { enable = true },
			ensure_installed = {
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
			},
		},
		config = function(_, opts)
			require("nvim-treesitter").setup(opts)
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "BufReadPost",
		opts = { mode = "cursor", max_lines = 3 },
	},
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		keys = {
			{
				"<leader>ue",
				function()
					require("edgy").toggle()
				end,
				desc = "Edgy Toggle",
			},
			{
				"<leader>uE",
				function()
					require("edgy").select()
				end,
				desc = "Edgy Select Window",
			},
		},
		opts = {
			bottom = {
				{
					ft = "toggleterm",
					size = { height = 0.4 },
					filter = function(buf, win)
						return vim.api.nvim_win_get_config(win).relative == ""
					end,
				},
				{
					ft = "noice",
					size = { height = 0.4 },
					filter = function(buf, win)
						return vim.api.nvim_win_get_config(win).relative == ""
					end,
				},
				"Trouble",
				{ ft = "qf", title = "Quickfix" },
				{ ft = "help", size = { height = 20 }, only = true },
			},
			left = {
				{
					ft = "neo-tree",
					title = "Neo-Tree",
					size = { width = 25 },
					filter = function(buf)
						return vim.b[buf].neo_tree_source == "filesystem"
					end,
				},
				{ ft = "aerial", title = "Aerial", size = { width = 25 } },
			},
		},
	},
	{
		"gbprod/yanky.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{ "<leader>py", "<cmd>YankyRingHistory<cr>", desc = "Open Yank History" },
			{ "[p", "<Plug>(YankyCycleForward)", desc = "Cycle Forward Through Yank History" },
			{ "]p", "<Plug>(YankyCycleBackward)", desc = "Cycle Backward Through Yank History" },
		},
	},
	{
		"folke/todo-comments.nvim",
		cmd = { "TodoTrouble", "TodoFzfLua" },
		event = { "BufReadPost", "BufNewFile" },
		opts = {},
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next Todo Comment",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous Todo Comment",
			},
			{ "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
			{ "<leader>zt", "<cmd>TodoFzfLua<cr>", desc = "Todo (FzfLua)" },
		},
	},
	{
		"saghen/blink.cmp",
		enabled = function()
			return vim.g.completion_engine == "blink"
		end,
		version = "*",
		event = { "InsertEnter", "CmdlineEnter" },
		opts = {
			keymap = {
				preset = "none",
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide", "fallback" },
				["<CR>"] = { "accept", "fallback" },
				["<C-n>"] = { "select_next", "show" },
				["<C-p>"] = { "select_prev", "fallback" },
				["<C-d>"] = { "scroll_documentation_down", "fallback" },
				["<C-u>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "snippet_forward", "fallback" },
				["<C-g>"] = { "snippet_backward", "fallback" },
				["<m-/>"] = { "show", "fallback" },
				["<space>"] = {
					"fallback",
				},
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				providers = {
					cmdline_history = {
						name = "History",
						module = "blink_cmdline_history",
						score_offset = -10,
						opts = {},
					},
					path = {
						opts = {
							get_cwd = function(_)
								return vim.fn.getcwd()
							end,
						},
					},
					buffer = {
						min_keyword_length = 4,
					},
				},
			},
			snippets = {
				preset = "default",
			},
			cmdline = {
				enabled = true,
				keymap = {
					["<Tab>"] = { "show_and_insert_or_accept_single", "select_next" },
					["<S-Tab>"] = { "show_and_insert_or_accept_single", "select_prev" },
					["<C-n>"] = { "select_next", "fallback" },
					["<C-p>"] = { "select_prev", "fallback" },
					["<Down>"] = { "select_next", "fallback" },
					["<Up>"] = { "select_prev", "fallback" },
					["<CR>"] = { "accept_and_enter", "fallback" },
					["<C-y>"] = { "select_and_accept", "fallback" },
					["<C-e>"] = { "cancel", "fallback" },
				},
				sources = function()
					local t = vim.fn.getcmdtype()
					if t == ":" or t == "@" then
						return { "cmdline", "path", "cmdline_history", "buffer" }
					elseif t == "/" or t == "?" then
						return { "cmdline_history", "buffer" }
					end
					return { "buffer" }
				end,
				completion = {
					menu = { auto_show = true },
					list = { selection = { preselect = false, auto_insert = true } },
					ghost_text = { enabled = true },
				},
			},
			completion = {
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 500,
					window = { border = "single" },
				},
				menu = {
					border = "single",
				},
				list = {
					selection = {
						preselect = false,
						auto_insert = false,
					},
				},
			},
		},
	},
}

if not isEmptyTable(langservers) then
	lazyPackages = TableConcat(lazyPackages, {
		-- {
		-- 	"ravitemer/mcphub.nvim",
		-- 	build = "npm install -g mcp-hub@latest",
		-- 	config = function()
		-- 		require("mcphub").setup()
		-- 	end,
		-- },
		{
			"olimorris/codecompanion.nvim",
			event = "VeryLazy",
			opts = {
				strategies = {
					chat = {
						adapter = "gemini",
						tools = {
							["mcp"] = {
								callback = function()
									return require("mcphub.extensions.codecompanion")
								end,
								description = "Call tools and resources from the MCP Servers",
								opts = {
									requires_approval = true,
									show_result_in_chat = true,
									make_vars = true,
									make_slash_commands = true,
								},
							},
						},
					},
					inline = {
						adapter = "gemini",
					},
					cmd = {
						adapter = "gemini",
					},
				},
				adapters = {
					gemini = function()
						return require("codecompanion.adapters").extend("gemini", {
							schema = {
								model = {
									default = "gemini-2.5-flash",
								},
							},
						})
					end,
					ollama = function()
						return require("codecompanion.adapters").extend("ollama", {
							schema = {
								model = {
									default = vim.g.ollama_agent_model or "gemma2:9b",
								},
							},
						})
					end,
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

-- Project Session Manager: auto-save/restore session per working directory
local session_dir = vim.fn.stdpath("state") .. "/sessions/"
vim.fn.mkdir(session_dir, "p")

local function get_session_file()
	local name = vim.fn.getcwd():gsub("/", "%%")
	return session_dir .. name .. ".vim"
end

vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		if #vim.fn.getbufinfo({ buflisted = 1 }) > 0 then
			vim.cmd("silent! mksession! " .. get_session_file())
		end
	end,
})

vim.keymap.set("n", "<leader>qs", function()
	local file = get_session_file()
	if vim.fn.filereadable(file) == 1 then
		vim.cmd("source " .. file)
	else
		print("No session saved for this directory")
	end
end, { desc = "Restore session" })

-- Auto-detect external changes and reload files
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	callback = function()
		if vim.fn.mode() ~= "c" then
			vim.cmd("checktime")
		end
	end,
})

-- Git conflict markers navigation
vim.keymap.set("n", "]x", "/^<<<<<<<\\|^=======\\|^>>>>>>>/e<CR>", { silent = true, desc = "Next Git conflict" })
vim.keymap.set("n", "[x", "?^<<<<<<<\\|^=======\\|^>>>>>>>?e<CR>", { silent = true, desc = "Prev Git conflict" })

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
	local win, buf = get_term_win_in_tab()
	local valid = get_valid_term_bufs()
	if not buf then
		return "0/" .. #valid
	end
	local idx = indexOf(valid, buf) or 0
	return idx .. "/" .. #valid
end

function HasTerminal()
	return #get_valid_term_bufs() > 0
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
		if vim.bo[value.bufnr].filetype == "terminal" then
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

function NewTerminal()
	local win, buf = get_term_win_in_tab()
	if not win then
		GotoMainWindow()
		vim.cmd("leftabove split")
		vim.cmd("resize " .. math.floor(vim.o.lines * 0.4))
	else
		vim.api.nvim_set_current_win(win)
	end
	vim.cmd("terminal")
	local new_buf = vim.api.nvim_get_current_buf()
	table.insert(term_bufs, new_buf)
	last_active_idx = #term_bufs
	setup_terminal_buffer(new_buf, "t" .. last_active_idx)
	vim.cmd("startinsert")
end

function TermToggle()
	local win, buf = get_term_win_in_tab()
	if win then
		vim.api.nvim_win_close(win, true)
	else
		GotoMainWindow()
		vim.cmd("leftabove split")
		vim.cmd("resize " .. math.floor(vim.o.lines * 0.4))

		local target_buf = term_bufs[math.min(last_active_idx, #term_bufs)]
		if target_buf and vim.api.nvim_buf_is_valid(target_buf) then
			vim.api.nvim_set_current_buf(target_buf)
		else
			vim.cmd("terminal")
			local new_buf = vim.api.nvim_get_current_buf()
			if last_active_idx > 0 then
				term_bufs[last_active_idx] = new_buf
			else
				table.insert(term_bufs, new_buf)
				last_active_idx = #term_bufs
			end
			setup_terminal_buffer(new_buf, "t" .. last_active_idx)
		end
		vim.cmd("startinsert")
	end
end

function FzfBuffer()
	if vim.bo.buftype == "terminal" then
		SafeRequire("fzf-lua").buffers()
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

function WinPick()
	local tab = vim.api.nvim_get_current_tabpage()
	local wins = vim.api.nvim_tabpage_list_wins(tab)

	local pickable = {}
	for _, win in ipairs(wins) do
		local buf = vim.api.nvim_win_get_buf(win)
		local win_info = vim.fn.getwininfo(win)[1]
		local ft = vim.bo[buf].filetype

		local is_valid = true
		if win_info == nil or win_info.height == nil or win_info.height < 2 then
			is_valid = false
		elseif #ft == 0 or vim.tbl_contains({ "fidget", "notify" }, ft) then
			is_valid = false
		end

		if is_valid then
			table.insert(pickable, win)
		end
	end

	if #pickable == 0 then
		return
	end
	if #pickable == 1 then
		vim.api.nvim_set_current_win(pickable[1])
		return
	end

	local chars = { "A", "S", "D", "F", "G", "H", "J", "K", "L", "Q", "W", "E", "R" }
	local win_map = {}
	local floats = {}

	for i, win in ipairs(pickable) do
		local char = chars[i] or tostring(i)
		win_map[char] = win

		local width = vim.api.nvim_win_get_width(win)
		local height = vim.api.nvim_win_get_height(win)
		local row = math.floor(height / 2)
		local col = math.floor(width / 2)

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { " " .. char .. " " })

		local float = vim.api.nvim_open_win(buf, false, {
			relative = "win",
			win = win,
			row = row,
			col = col - 1,
			width = 3,
			height = 1,
			style = "minimal",
			border = "single",
		})
		vim.api.nvim_set_option_value("winhl", "Normal:DiffAdd", { scope = "local", win = float })
		table.insert(floats, float)
	end

	vim.cmd("redraw")

	local ok, char = pcall(vim.fn.getcharstr)
	for _, float in ipairs(floats) do
		pcall(vim.api.nvim_win_close, float, true)
	end

	if ok then
		local target = win_map[char:upper()]
		if target then
			vim.api.nvim_set_current_win(target)
		end
	end
end

local function MoveToWindow()
	WinPick()
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

		vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
			pattern = "*/.github/workflows/*.y*ml",
			callback = function()
				vim.bo.filetype = "yaml.github"
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
	local win, buf = get_term_win_in_tab()
	if not win then
		TermToggle()
		win, buf = get_term_win_in_tab()
	end
	if win then
		vim.api.nvim_set_current_win(win)
		local mode = vim.fn.mode()
		if mode == "t" then
			vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<c-c><c-p><cr>", true, true, true), "t")
		else
			vim.cmd("startinsert")
			vim.defer_fn(function()
				vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<c-p><cr>", true, true, true), "t")
			end, 50)
		end
	end
end

function RunShellAndShow(command)
	local win, buf = get_term_win_in_tab()
	if not win then
		TermToggle()
		win, buf = get_term_win_in_tab()
	end
	if win and buf then
		local chan = vim.bo[buf].channel
		vim.api.nvim_chan_send(chan, command .. "\r")
		vim.api.nvim_set_current_win(win)
		vim.cmd("startinsert")
	end
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

function ToggleMaximize()
	local win_height = vim.api.nvim_win_get_height(0)
	local win_width = vim.api.nvim_win_get_width(0)
	local max_height = vim.o.lines - vim.o.cmdheight - 1
	local max_width = vim.o.columns

	if win_height >= max_height - 1 and win_width >= max_width - 1 then
		vim.cmd("wincmd =")
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			local buf = vim.api.nvim_win_get_buf(win)
			local buf_name = vim.api.nvim_buf_get_name(buf)
			local ft = vim.bo[buf].filetype
			if string.match(buf_name, "crush") then
				vim.api.nvim_win_set_width(win, 80)
			elseif ft == "neo-tree" then
				vim.api.nvim_win_set_width(win, 25)
			end
		end
	else
		vim.cmd("wincmd _")
		vim.cmd("wincmd |")
	end
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
	local close_on_exit = opts.autoclose or false

	local old_buf = get_term_by_name(name)
	if old_buf then
		pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
	end

	local buf = vim.api.nvim_create_buf(false, true)
	setup_terminal_buffer(buf, name)

	local win, cur_buf = get_term_win_in_tab()
	if not win then
		GotoMainWindow()
		vim.cmd("leftabove split")
		vim.cmd("resize " .. math.floor(vim.o.lines * 0.4))
		win = vim.api.nvim_get_current_win()
	end
	vim.api.nvim_win_set_buf(win, buf)

	local cmd = command
	if opts.shell then
		cmd = string.format('sh -c "%s%s;exit 0"', command, notify_command)
	end

	vim.api.nvim_buf_call(buf, function()
		vim.fn.termopen(cmd, {
			on_exit = function(job_id, exit_code, event)
				if close_on_exit or exit_code == 0 then
					pcall(vim.api.nvim_buf_delete, buf, { force = true })
				end
			end,
		})
	end)

	local found = false
	for i, b in ipairs(term_bufs) do
		if b == buf then
			found = true
			break
		end
	end
	if not found then
		table.insert(term_bufs, buf)
		last_active_idx = #term_bufs
	end

	vim.cmd("startinsert")
end

function KillAndRerunTermWrapper(command, opts)
	local name = string.gsub(command, " ", "_")
	KillAndRerunTerm(name, command)
	vim.defer_fn(function()
		vim.cmd("startinsert")
	end, 50)
end

function RunCurrentLine()
	local cmd = tostring(vim.api.nvim_get_current_line())
	KillAndRerunTermWrapper(cmd)
end

function EditFile(path)
	if path == nil or path == "" then
		return
	end
	local expanded = vim.fn.expand(path)
	local stat = vim.uv.fs_stat(expanded)
	GotoMainWindow()
	if stat and stat.type == "directory" then
		require("oil").open(expanded)
	else
		pcall(vim.cmd, "e " .. vim.fn.fnameescape(expanded))
	end
end

function OilReuseBuf(dir)
	if dir == nil or dir == "" then
		return
	end
	local cur_buf = vim.api.nvim_get_current_buf()
	local cur_name = vim.api.nvim_buf_get_name(cur_buf)
	if not cur_name:match("^oil://") then
		require("oil").open(dir)
		return
	end
	-- 多個 oil buffer 同時存在時，nvim_buf_set_name 對 oil:// URL 重新命名會靜默失敗
	-- 這時 fallback 走 oil.open 標準路徑（會建立新 buffer）
	local oil_count = 0
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_name(b):match("^oil://") then
			oil_count = oil_count + 1
		end
	end
	if oil_count > 1 then
		require("oil").open(dir)
		return
	end
	local abs
	if dir:match("^oil://") then
		abs = dir:gsub("^oil://", ""):gsub("/$", "")
	else
		abs = vim.fn.fnamemodify(dir, ":p"):gsub("/$", "")
	end
	if abs == "" then
		abs = "/"
	end
	local new_name = "oil://" .. abs .. "/"
	if cur_name == new_name then
		return
	end
	pcall(vim.api.nvim_buf_set_name, cur_buf, "/tmp/_oil_inter_" .. cur_buf)
	pcall(vim.api.nvim_buf_set_name, cur_buf, new_name)
	if vim.api.nvim_buf_get_name(cur_buf) ~= new_name then
		-- rename 失敗，fallback
		require("oil").open(dir)
		return
	end
	vim.b[cur_buf].filetype = nil
	vim.bo[cur_buf].filetype = ""
	require("oil.loading").set_loading(cur_buf, false)
	require("oil").load_oil_buffer(cur_buf)
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
		elseif vim.bo[value.bufnr].filetype == "terminal" then
			vim.api.nvim_set_current_win(value.winid)
			vim.cmd("startinsert")
			return
		end
	end
end

function UpdateTitleString()
	local hostname = vim.fn.hostname()
	local name = vim.fn.expand("%")
	if vim.bo.filetype == "terminal" then
		name = vim.fn.escape(termTitle(), "|")
	end
	pcall(vim.cmd, string.format("let &titlestring='%s - %s'", hostname, name))
end

function FloatermNext(offset)
	local win, buf = get_term_win_in_tab()
	if not win then
		TermToggle()
		return
	end

	local valid = get_valid_term_bufs()
	if #valid <= 1 then
		return
	end

	local idx = indexOf(valid, buf) or 1
	local next_idx = idx + offset
	if next_idx > #valid then
		next_idx = 1
	elseif next_idx < 1 then
		next_idx = #valid
	end

	local next_buf = valid[next_idx]
	for i, b in ipairs(term_bufs) do
		if b == next_buf then
			last_active_idx = i
			break
		end
	end

	vim.api.nvim_win_set_buf(win, next_buf)
	vim.api.nvim_set_current_win(win)
	vim.cmd("startinsert")
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

-- SafeRequire("nvim-web-devicons").setup({}) -- Configured in lazyPackages

vim.g.EINK_WIDTH = vim.env.EINK_WIDTH
local function checkIsEink()
	if vim.env.LC_IS_EINK == "1" or vim.env.LC_IS_EINK == "true" then
		vim.schedule(function()
			vim.o.background = "light"
		end)
		return
	end
	if vim.env.COLORFGBG and vim.env.COLORFGBG:sub(1, 3) == "15;" then
		vim.schedule(function()
			vim.o.background = "light"
		end)
		return
	end
	if vim.g.fullWidth ~= vim.o.columns then
		if vim.g.EINK_WIDTH and vim.g.EINK_WIDTH ~= "" and tostring(vim.o.columns) == vim.g.EINK_WIDTH then
			vim.schedule(function()
				vim.o.background = "light"
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
				KillAndRerunTerm(name, "pueue follow " .. data[1], { autoclose = false, shell = true })
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

-- Crush Agent Native Toggle (Pure Lua)
local crush_buf = nil
local crush_win = nil

local function toggle_crush()
	-- If window is open and valid, close it
	if crush_win and vim.api.nvim_win_is_valid(crush_win) then
		vim.api.nvim_win_close(crush_win, true)
		crush_win = nil
		return
	end

	-- If buffer is valid, split and show
	if crush_buf and vim.api.nvim_buf_is_valid(crush_buf) then
		vim.cmd("vertical split")
		crush_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_width(crush_win, 80)
		vim.api.nvim_win_set_buf(crush_win, crush_buf)
		vim.cmd("startinsert")
		return
	end

	-- Create split and open terminal
	vim.cmd("vertical split")
	crush_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_width(crush_win, 80)

	vim.cmd("terminal crush")
	crush_buf = vim.api.nvim_get_current_buf()

	vim.bo[crush_buf].buflisted = false
	vim.cmd("startinsert")
end

vim.keymap.set("n", "<leader>cr", toggle_crush, { desc = "Toggle Crush Agent" })
