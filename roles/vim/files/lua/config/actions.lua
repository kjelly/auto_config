local api = vim.api

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
	if currentFile ~= "" and not vim.startswith(currentFile, cwd .. "/") then
		require("fzf-lua").files()
		return
	end
	require("fzf-lua-enchanted-files").files()
end

vim.api.nvim_set_keymap("n", "<c-p>", "", {
	silent = true,
	callback = FindFileCwd,
	desc = "Find file",
})

function FindFileBuffer()
	local currentBufferPath = vim.fn.expand("%:p:h")
	GotoMainWindow()
	require("fzf-lua").files({ cwd = currentBufferPath })
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

function FzfBuffer()
	if vim.bo.buftype == "terminal" then
		require("fzf-lua").buffers()
	else
		GotoMainWindow()
		if #GetBuffers({}) > 1 then
			require("fzf-lua").buffers()
		else
			FindFileCwd()
		end
	end
end

function UpdateEnv()
	if vim.fn.filereadable("poetry.lock") == 0 or vim.fn.executable("poetry") == 0 then
		return
	end
	vim.system(
		{ "poetry", "env", "info", "--path" },
		{ text = true },
		vim.schedule_wrap(function(result)
			local path = vim.trim(result.stdout or "")
			if result.code ~= 0 or path == "" then
				return
			end
			vim.env.VIRTUAL_ENV = path
			vim.env.PATH = path .. "/bin:" .. vim.env.PATH
			require("dap-python").setup(path .. "/bin/python3")
			-- Restart only existing Python clients, with their updated environment.
			for _, client in ipairs(vim.lsp.get_clients()) do
				if vim.tbl_contains({ "pyright", "ruff" }, client.name) then
					local config, buffers = client.config, vim.lsp.get_buffers_by_client_id(client.id)
					client:stop()
					vim.defer_fn(function()
						for _, buf in ipairs(buffers) do
							if vim.api.nvim_buf_is_valid(buf) then
								vim.api.nvim_buf_call(buf, function()
									vim.lsp.start(config)
								end)
							end
						end
					end, 100)
				end
			end
		end)
	)
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
		vim.bo[buf].bufhidden = "wipe"
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
	vim.o.laststatus = vim.o.laststatus == 0 and 3 or 0
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

function GetVisualSelection()
	local s_start = vim.fn.getpos("'<")
	local s_end = vim.fn.getpos("'>")
	local n_lines = math.abs(s_end[2] - s_start[2]) + 1
	local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
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

function EditFile(path)
	if path == nil or path == "" then
		return
	end
	local expanded = vim.fn.expand(path)
	if not vim.uv.fs_stat(vim.fs.dirname(expanded)) then
		vim.fn.mkdir(vim.fs.dirname(expanded), "p")
	end
	local stat = vim.uv.fs_stat(expanded)
	GotoMainWindow()
	if stat and stat.type == "directory" then
		require("oil").open(expanded)
	else
		pcall(vim.cmd, "e " .. vim.fn.fnameescape(expanded))
	end
end

function RegistersInsert()
	require("fzf-lua").registers()
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
