-- Isolated menu integration checks: real keymaps, selection and terminal buffers.
local api = vim.api
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.o.swapfile = false
vim.o.shadafile = "NONE"
local copied = {}
vim.g.clipboard = {
	name = "gamepad-test",
	copy = {
		["+"] = function(text, kind)
			copied = { text = text, kind = kind }
		end,
		["*"] = function() end,
	},
	paste = {
		["+"] = function()
			return { copied.text or {}, copied.kind or "v" }
		end,
		["*"] = function()
			return { {}, "v" }
		end,
	},
}
local notifications = {}
vim.notify = function(message)
	notifications[#notifications + 1] = message
end
vim.keymap.set("n", "<Space>h", "<C-w>h")
vim.keymap.set("x", "<CR>", '"+y')
local original_window_mapping = vim.fn.maparg(" h", "n")
require("config.gamepad").setup()
local checks = {}
local function check(name, fn)
	local ok, err = xpcall(fn, debug.traceback)
	checks[#checks + 1] = { name = name, ok = ok, err = err }
	-- Recover UI state after a failed assertion so later checks stay independent.
	vim.cmd.normal({ args = { vim.keycode("<Esc>") }, bang = true })
	for _, win in ipairs(api.nvim_list_wins()) do
		if api.nvim_win_get_config(win).relative ~= "" then
			pcall(api.nvim_win_close, win, true)
		end
	end
	vim.wait(20, function()
		return false
	end, 1)
end
local function press(keys)
	api.nvim_feedkeys(vim.keycode(keys), "xt", false)
	vim.wait(20, function()
		return false
	end, 1)
end
local function open()
	press("<Space><Space>")
	assert(vim.bo.filetype == "gamepad-menu", "menu did not open")
end
local function select_item(label)
	local rows = api.nvim_buf_get_lines(0, 0, -1, false)
	local target
	for i, row in ipairs(rows) do
		if vim.trim(row) == label then
			target = i
		end
	end
	assert(target, "missing menu item: " .. label)
	for _ = 2, target do
		press("<Down>")
	end
	press("<CR>")
end
local function scratch(lines)
	vim.cmd("enew!")
	api.nvim_buf_set_lines(0, 0, -1, false, lines or { "alpha 世界 omega", "second line", "third line" })
	api.nvim_win_set_cursor(0, { 1, 0 })
end
scratch()
check("menu opens without a word under the cursor", function()
	scratch({ "" })
	open()
	select_item("複製目前單字")
	assert(vim.bo.filetype ~= "gamepad-menu")
	scratch()
end)
check("menu navigation, Esc and Backspace preserve the origin", function()
	local win, buf, cursor = api.nvim_get_current_win(), api.nvim_get_current_buf(), api.nvim_win_get_cursor(0)
	open()
	assert(api.nvim_win_get_cursor(0)[1] == 1)
	press("<Down><Tab>")
	assert(api.nvim_win_get_cursor(0)[1] == 3)
	press("<Up>")
	assert(api.nvim_win_get_cursor(0)[1] == 2)
	press("<Esc>")
	assert(api.nvim_get_current_win() == win and api.nvim_get_current_buf() == buf)
	assert(vim.deep_equal(api.nvim_win_get_cursor(0), cursor))
	open()
	press("<BS>")
	assert(api.nvim_get_current_win() == win)
	assert(vim.fn.maparg(" h", "n") == original_window_mapping, "existing localleader mapping changed")
end)
check("copy line and word to the clipboard", function()
	open()
	select_item("複製目前行")
	assert(copied.text[1] == "alpha 世界 omega" and copied.kind == "V")
	open()
	select_item("複製目前單字")
	assert(copied.text[1] == "alpha" and copied.kind == "v")
end)
check("start selection and copy with the existing Enter mapping", function()
	open()
	select_item("開始選取文字")
	assert(vim.fn.mode() == "v", "selection did not start")
	press("<Right><Right><CR>")
	assert(copied.text[1] == "alp", vim.inspect(copied))
	assert(vim.fn.mode() == "n")
end)
check("visual menu cancellation restores Unicode selection", function()
	api.nvim_win_set_cursor(0, { 1, 6 })
	vim.cmd.normal({ args = { "v" }, bang = true })
	press("<Right>")
	local anchor, cursor = vim.fn.getpos("v"), api.nvim_win_get_cursor(0)
	open()
	press("<Esc>")
	assert(vim.fn.mode() == "v", "visual selection was lost on cancellation")
	assert(vim.deep_equal(vim.fn.getpos("v"), anchor))
	assert(vim.deep_equal(api.nvim_win_get_cursor(0), cursor))
	open()
	select_item("複製選取文字")
	assert(copied.text[1] == "世界", vim.inspect(copied))
end)
check("linewise menu selection preserves register type", function()
	api.nvim_win_set_cursor(0, { 1, 0 })
	open()
	select_item("開始整行選取")
	assert(vim.fn.mode() == "V")
	press("<Down>")
	open()
	select_item("複製選取文字")
	assert(
		copied.kind == "V" and table.concat(copied.text, "\n") == "alpha 世界 omega\nsecond line\n",
		vim.inspect(copied)
	)
end)
check("save acts on the source file", function()
	local path = vim.fn.tempname()
	scratch({ "saved using gamepad" })
	api.nvim_buf_set_name(0, path)
	open()
	select_item("儲存檔案")
	assert(vim.fn.readfile(path)[1] == "saved using gamepad")
	assert(not vim.bo.modified)
	vim.fn.delete(path)
end)
check("select raw terminals and switch back without closing them", function()
	scratch()
	local editor_win, editor_buf = api.nvim_get_current_win(), api.nvim_get_current_buf()
	-- Opening and cancelling records the editor before creating terminal windows.
	open()
	press("<Esc>")
	vim.cmd("split")
	vim.cmd("enew!")
	local job = vim.fn.jobstart({ "sh" }, { term = true })
	assert(job > 0)
	local terminal_win, terminal_buf = api.nvim_get_current_win(), api.nvim_get_current_buf()
	api.nvim_set_current_win(editor_win)
	open()
	select_item("選擇 Terminal")
	assert(vim.bo.filetype == "gamepad-menu", "terminal selector did not open")
	press("<CR>")
	assert(api.nvim_get_current_buf() == terminal_buf)
	assert(vim.fn.mode() == "n")
	open()
	select_item("切換編輯區 / Terminal")
	assert(api.nvim_get_current_win() == editor_win and api.nvim_get_current_buf() == editor_buf)
	assert(api.nvim_win_is_valid(terminal_win) and api.nvim_buf_is_valid(terminal_buf))
	open()
	select_item("切換編輯區 / Terminal")
	assert(api.nvim_get_current_win() == terminal_win)
	assert(vim.fn.maparg("  ", "t") == "", "terminal spaces must reach the shell")
	vim.fn.jobstop(job)
	api.nvim_set_current_win(editor_win)
	api.nvim_win_close(terminal_win, true)
	api.nvim_buf_delete(terminal_buf, { force = true })
end)
local failed = 0
for _, result in ipairs(checks) do
	io.stdout:write((result.ok and "PASS " or "FAIL ") .. result.name .. "\n")
	if not result.ok then
		failed = failed + 1
		io.stdout:write(result.err .. "\n")
	end
end
io.stdout:flush()
vim.cmd(failed == 0 and "noautocmd qa!" or "noautocmd cquit")
