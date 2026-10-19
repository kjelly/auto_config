local terminal = require("config.terminal")
local get_term_win_in_tab = terminal.get_window
local get_valid_term_bufs = terminal.get_buffers
local indexOf = terminal.index_of
local termTitle = terminal.title

return {
	{ "junegunn/fzf", lazy = true, build = "./install --bin" },
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
			picker = { enabled = false },
			quickfile = { enabled = true },
			scroll = { enabled = false },
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
	{ "danymat/neogen", cmd = "Neogen", opts = {} },
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
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		lazy = true,
		keys = { "<localleader>du" },
		opts = {},
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
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
								return require("noice").api.status.mode.get()
							end,
							cond = function()
								local n = require("noice")
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
		cmd = "Neotree",
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
		event = "VeryLazy",
		dependencies = { "MunifTanjim/nui.nvim" },
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
	{ "FabijanZulj/blame.nvim", cmd = "BlameToggle", opts = {} },
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
				{ "<leader>a", group = "Code actions" },
				{ "<leader>b", group = "Buffer/Bookmark" },
				{ "<leader>bc", desc = "Copy file path" },
				{ "<leader>c", group = "Comment/cd" },
				{ "<leader>d", group = "doc" },
				{ "<leader>e", group = "Edit" },
				{ "<leader>ecw", desc = "full file" },
				{ "<leader>es", desc = "setting/notes" },
				{ "<leader>f", group = "File" },
				{ "<leader>g", group = "Git" },
				{ "<leader>ga", group = "Amend" },
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
				{ "<leader>v", group = "View" },
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
	require("config.lsp"),
	{
		"stevearc/conform.nvim",
		event = { "BufReadPost", "BufWritePre" },
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				go = { "goimports", "gofmt", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				yaml = { "prettierd", "prettier", stop_after_first = true },
				["yaml.github"] = { "prettierd", "prettier", stop_after_first = true },
				["yaml.ansible"] = { "prettierd", "prettier", stop_after_first = true },
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
	{ "dstein64/vim-startuptime", cmd = "StartupTime" },
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
	{
		"ibhagwan/fzf-lua",
		dependencies = { "junegunn/fzf" },
		cmd = "FzfLua",
		config = function()
			local fzf = require("fzf-lua")
			local icons = { git_icons = false, file_icons = false, color_icons = false }
			fzf.setup({ files = icons, buffers = icons, grep = icons, git = { files = icons } })
			fzf.register_ui_select()
		end,
	},
	{
		"otavioschwanck/fzf-lua-enchanted-files",
		dependencies = { "ibhagwan/fzf-lua" },
		config = function()
			-- Modern configuration using vim.g
			vim.g.fzf_lua_enchanted_files = {
				max_history_per_cwd = 50,
				history_dir = vim.fn.stdpath("state") .. "/fzf-lua-enchanted-files",
			}
		end,
	},
	{ "lambdalisue/suda.vim" },
	{ "ianding1/leetcode.vim", cmd = { "LeetCodeList", "LeetCodeSubmit", "LeetCodeTest" } },
	{
		"Mofiqul/vscode.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("vscode-eink")
		end,
	},
	{ "m-gail/escape.nvim" },
	{
		"stevearc/oil.nvim",
		lazy = false,
		opts = {
			view_options = {
				sort = {
					{ "type", "asc" },
					{ "name", "asc" },
				},
				show_hidden = false,
			},
			keymaps = {
				["<BS>"] = "actions.parent",
				["_"] = function()
					require("oil").open(vim.fn.getcwd())
				end,
				["`"] = "actions.cd",
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
	require("config.completion"),
	{ "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
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
	require("config.treesitter"),
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
		"olimorris/codecompanion.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "ibhagwan/fzf-lua" },
		cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
		opts = {
			interactions = {
				chat = {
					adapter = "gemini",
				},
				inline = {
					adapter = "gemini",
				},
				cmd = {
					adapter = "gemini",
				},
			},
			adapters = {
				http = {
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
	},
	{
		"arborist-ts/arborist.nvim",
		lazy = true,
		branch = "main",
	},
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = { "CopilotChat", "CopilotChatToggle", "CopilotChatReset" },
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
}
