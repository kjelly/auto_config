local M = {}
local api = vim.api
local active_menu
local last_editor
local visual_modes = { v = true, V = true, ["\022"] = true }

local function context()
	local mode = vim.fn.mode()
	local has_word, word = pcall(vim.fn.expand, "<cword>")
	local ctx = {
		win = api.nvim_get_current_win(),
		buf = api.nvim_get_current_buf(),
		cursor = api.nvim_win_get_cursor(0),
		view = vim.fn.winsaveview(),
		tick = api.nvim_buf_get_changedtick(0),
		word = has_word and word or "",
		line = api.nvim_get_current_line(),
	}
	if visual_modes[mode] then
		ctx.mode = mode
		ctx.anchor = vim.fn.getpos("v")
		ctx.text = vim.fn.getregion(ctx.anchor, vim.fn.getpos("."), { type = mode })
		vim.cmd.normal({ args = { vim.keycode("<Esc>") }, bang = true })
	end
	if vim.bo[ctx.buf].buftype == "" then
		last_editor = { win = ctx.win, buf = ctx.buf }
	end
	return ctx
end

local function restore(ctx, selection)
	if
		not api.nvim_win_is_valid(ctx.win)
		or not api.nvim_buf_is_valid(ctx.buf)
		or api.nvim_win_get_buf(ctx.win) ~= ctx.buf
	then
		return false
	end
	api.nvim_set_current_win(ctx.win)
	vim.fn.winrestview(ctx.view)
	if selection and ctx.mode and api.nvim_buf_get_changedtick(ctx.buf) == ctx.tick then
		api.nvim_win_set_cursor(ctx.win, { ctx.anchor[2], ctx.anchor[3] - 1 })
		vim.cmd.normal({ args = { ctx.mode }, bang = true })
		api.nvim_win_set_cursor(ctx.win, ctx.cursor)
	end
	return true
end

-- A normal-mode float keeps the menu usable with a gamepad without a search prompt.
local function choose(ctx, title, items)
	local buf = api.nvim_create_buf(false, true)
	local labels, width = {}, 44
	for i, item in ipairs(items) do
		labels[i] = " " .. item.label .. " "
		width = math.max(width, vim.fn.strdisplaywidth(labels[i]))
	end
	width = math.max(1, math.min(width, vim.o.columns - 4))
	local height = math.max(1, math.min(#items, vim.o.lines - 6))
	api.nvim_buf_set_lines(buf, 0, -1, false, labels)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = "gamepad-menu"
	local win = api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = "single",
		width = width,
		height = height,
		row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
		col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
		title = " " .. title .. " ",
		title_pos = "center",
		footer = " ↑↓ / Tab 選擇 · Enter 執行 · Esc 返回 ",
		footer_pos = "center",
	})
	active_menu = win
	vim.wo[win].cursorline = true
	vim.wo[win].cursorlineopt = "line"
	vim.wo[win].wrap = false
	vim.wo[win].spell = false
	local closed = false
	local function finish(item, return_focus)
		if closed then
			return
		end
		closed = true
		active_menu = nil
		if api.nvim_win_is_valid(win) then
			api.nvim_win_close(win, true)
		end
		if return_focus == false then
			return
		end
		vim.schedule(function()
			if not restore(ctx, not item) then
				return
			end
			if item then
				local ok, err = pcall(item.action)
				if not ok then
					vim.notify("手把選單：" .. tostring(err), vim.log.levels.ERROR)
				end
			end
		end)
	end
	local function move(delta)
		local row = api.nvim_win_get_cursor(win)[1]
		api.nvim_win_set_cursor(win, { (row - 1 + delta) % #items + 1, 0 })
	end
	local function map(keys, callback)
		vim.keymap.set("n", keys, callback, { buffer = buf, silent = true, nowait = true })
	end
	for _, key in ipairs({ "<Down>", "<Tab>", "j" }) do
		map(key, function()
			move(1)
		end)
	end
	for _, key in ipairs({ "<Up>", "<S-Tab>", "k" }) do
		map(key, function()
			move(-1)
		end)
	end
	map("<CR>", function()
		finish(items[api.nvim_win_get_cursor(win)[1]])
	end)
	for _, key in ipairs({ "<Esc>", "<BS>", "q" }) do
		map(key, function()
			finish()
		end)
	end
	api.nvim_create_autocmd("WinLeave", {
		buffer = buf,
		once = true,
		callback = function()
			vim.schedule(function()
				finish(nil, false)
			end)
		end,
	})
	api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(win),
		once = true,
		callback = function()
			vim.schedule(function()
				finish(nil, false)
			end)
		end,
	})
end

local function copy(text, kind, label)
	vim.fn.setreg('"', text, kind)
	vim.fn.setreg("+", text, kind)
	vim.notify("已複製" .. label)
end

local function terminals()
	return vim.tbl_filter(function(buf)
		return vim.bo[buf].buftype == "terminal"
	end, api.nvim_list_bufs())
end

local function show_terminal(buf)
	if not buf then
		require("config.terminal").NewTerminal()
		vim.cmd.stopinsert()
		return api.nvim_get_current_buf()
	end
	for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
		if api.nvim_win_get_buf(win) == buf then
			api.nvim_set_current_win(win)
			return buf
		end
	end
	local win = require("config.terminal").get_window()
	if win then
		api.nvim_set_current_win(win)
	else
		vim.cmd("leftabove split")
		api.nvim_win_set_height(0, math.max(1, math.floor(vim.o.lines * 0.4)))
	end
	api.nvim_win_set_buf(0, buf)
	return buf
end

local function toggle_terminal(ctx)
	if vim.bo[ctx.buf].buftype ~= "terminal" then
		local _, buf = require("config.terminal").get_window()
		show_terminal(buf or terminals()[1])
		return
	end
	if last_editor and api.nvim_buf_is_valid(last_editor.buf) then
		if api.nvim_win_is_valid(last_editor.win) and api.nvim_win_get_buf(last_editor.win) == last_editor.buf then
			api.nvim_set_current_win(last_editor.win)
		else
			api.nvim_win_set_buf(0, last_editor.buf)
		end
		return
	end
	for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
		if api.nvim_win_get_config(win).relative == "" and vim.bo[api.nvim_win_get_buf(win)].buftype == "" then
			api.nvim_set_current_win(win)
			return
		end
	end
	-- Keep the shell running even when there is no previous editor window.
	api.nvim_win_set_buf(0, api.nvim_create_buf(true, false))
end

function M.open()
	if active_menu and api.nvim_win_is_valid(active_menu) then
		api.nvim_set_current_win(active_menu)
		return
	end
	local ctx = context()
	local items = {}
	local function add(label, action)
		items[#items + 1] = { label = label, action = action }
	end
	if ctx.mode then
		add("複製選取文字", function()
			copy(ctx.text, ctx.mode, "選取文字")
		end)
	end
	add("編輯工作區筆記 (,esn)", function()
		local mapping = vim.fn.maparg((vim.g.mapleader or "\\") .. "esn", "n", false, true)
		if type(mapping.callback) ~= "function" then
			error("找不到工作區筆記快捷鍵")
		end
		mapping.callback()
	end)
	add("開始選取文字", function()
		vim.cmd.normal({ args = { "v" }, bang = true })
	end)
	add("開始整行選取", function()
		vim.cmd.normal({ args = { "V" }, bang = true })
	end)
	add("複製目前行", function()
		copy({ ctx.line }, "V", "目前行")
	end)
	add("複製目前單字", function()
		if ctx.word ~= "" then
			copy(ctx.word, "v", "目前單字")
		end
	end)
	add("切換編輯區 / Terminal", function()
		toggle_terminal(ctx)
	end)
	add("選擇 Terminal", function()
		local choices = {}
		for _, buf in ipairs(terminals()) do
			local target = buf
			local name = vim.b[buf].floaterm_name or vim.b[buf].term_title or api.nvim_buf_get_name(buf)
			choices[#choices + 1] = {
				label = ("[%d] %s"):format(buf, name:gsub("[\r\n]", " ")),
				action = function()
					show_terminal(target)
				end,
			}
		end
		if #choices == 0 then
			vim.notify("目前沒有 Terminal；可選擇「新增 Terminal」")
		else
			choose(ctx, "選擇 Terminal", choices)
		end
	end)
	add("繼續 Terminal 輸入", function()
		local _, visible = require("config.terminal").get_window()
		local buf = show_terminal(vim.bo[ctx.buf].buftype == "terminal" and ctx.buf or visible or terminals()[1])
		local channel = vim.bo[buf].channel
		if channel > 0 and vim.fn.jobwait({ channel }, 0)[1] == -1 then
			vim.cmd.startinsert()
		else
			vim.notify("這個 Terminal 已結束，請新增 Terminal")
		end
	end)
	add("新增 Terminal", function()
		show_terminal()
	end)
	if vim.bo[ctx.buf].buftype == "" and api.nvim_buf_get_name(ctx.buf) ~= "" then
		add("儲存檔案", function()
			vim.cmd.update()
		end)
	end
	choose(ctx, "手把選單", items)
end

function M.setup()
	vim.keymap.set({ "n", "x" }, "<Space><Space>", M.open, { silent = true, desc = "手把選單" })
	api.nvim_create_user_command("GamepadMenu", M.open, { desc = "開啟手把選單", force = true })
end

return M
