local M = {}

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
local alt_d_previous_bufs = {}

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
	local active = term_bufs[last_active_idx]
	local valid = vim.tbl_filter(vim.api.nvim_buf_is_valid, term_bufs)
	term_bufs = valid
	last_active_idx = indexOf(valid, active) or math.max(1, math.min(last_active_idx, #valid))
	return valid
end

local function open_shell()
	vim.cmd.enew()
	local shell = vim.fn.exepath("nu")
	vim.fn.jobstart({ shell ~= "" and shell or vim.o.shell }, { term = true })
end

local function setup_terminal_buffer(bufnr, name)
	term_names[bufnr] = name
	vim.api.nvim_buf_set_var(bufnr, "floaterm_name", name)
	vim.bo[bufnr].filetype = "terminal"

	-- A native terminal writes "[Process exited 0]" into its buffer when its
	-- job ends normally. Remove that finished buffer instead, so M.TermToggle
	-- opens a fresh terminal without leaving the status line visible. Failed
	-- commands remain open so their output can still be inspected.
	vim.api.nvim_create_autocmd("TermClose", {
		buffer = bufnr,
		once = true,
		callback = function()
			if vim.v.event.status ~= 0 then
				return
			end
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end

				for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
					if vim.api.nvim_win_is_valid(win) and #vim.api.nvim_list_wins() > 1 then
						vim.api.nvim_win_close(win, true)
					end
				end
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end)
		end,
	})
end

local function get_term_by_name(name)
	for buf, n in pairs(term_names) do
		if n == name and vim.api.nvim_buf_is_valid(buf) then
			return buf
		end
	end
	return nil
end

function M.NativeTermSendTrimmed(mode)
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

	local win, buf = get_term_win_in_tab()
	if not win then
		M.TermToggle()
		win, buf = get_term_win_in_tab()
	end

	if win and buf then
		local chan = vim.bo[buf].channel
		vim.api.nvim_chan_send(chan, table.concat(lines, "\r") .. "\r")
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
	return SafeBufGetVar(0, "floaterm_name") or SafeBufGetVar(0, "term_title") or "terminal"
end

function M.HasTerminal()
	return #get_valid_term_bufs() > 0
end

function M.NewTerminal()
	local win, buf = get_term_win_in_tab()
	if not win then
		GotoMainWindow()
		vim.cmd("leftabove split")
		vim.cmd("resize " .. math.floor(vim.o.lines * 0.4))
	else
		vim.api.nvim_set_current_win(win)
	end
	open_shell()
	local new_buf = vim.api.nvim_get_current_buf()
	table.insert(term_bufs, new_buf)
	last_active_idx = #term_bufs
	setup_terminal_buffer(new_buf, "t" .. last_active_idx)
	vim.cmd("startinsert")
end

function M.TermToggle()
	local win, buf = get_term_win_in_tab()
	if win then
		if #vim.api.nvim_tabpage_list_wins(0) == 1 then
			vim.cmd.enew()
		else
			vim.api.nvim_win_close(win, true)
		end
	else
		GotoMainWindow()
		vim.cmd("leftabove split")
		vim.cmd("resize " .. math.floor(vim.o.lines * 0.4))

		local valid = get_valid_term_bufs()
		local target_buf = valid[math.min(last_active_idx, #valid)]
		if target_buf and vim.api.nvim_buf_is_valid(target_buf) then
			vim.api.nvim_set_current_buf(target_buf)
		else
			open_shell()
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

function M.AltDSwitch()
	local win = vim.api.nvim_get_current_win()
	local current_buf = vim.api.nvim_win_get_buf(win)
	if vim.bo[current_buf].buftype == "terminal" or vim.bo[current_buf].filetype == "terminal" then
		vim.cmd("stopinsert")
		local previous_buf = alt_d_previous_bufs[win]
		if previous_buf and vim.api.nvim_buf_is_valid(previous_buf) then
			vim.api.nvim_win_set_buf(win, previous_buf)
			alt_d_previous_bufs[win] = nil
		else
			GotoMainWindow()
		end
	else
		local _, term_buf = get_term_win_in_tab()
		local valid_term_bufs = get_valid_term_bufs()
		term_buf = term_buf or valid_term_bufs[math.min(last_active_idx, #valid_term_bufs)]

		alt_d_previous_bufs[win] = current_buf
		if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
			vim.api.nvim_win_set_buf(win, term_buf)
		else
			vim.api.nvim_set_current_win(win)
			open_shell()
			term_buf = vim.api.nvim_get_current_buf()
			table.insert(term_bufs, term_buf)
			last_active_idx = #term_bufs
			setup_terminal_buffer(term_buf, "t" .. last_active_idx)
		end
		vim.cmd("startinsert")
	end
end

function M.RunPreviousCommandFunc()
	local win, buf = get_term_win_in_tab()
	if not win then
		M.TermToggle()
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

function M.RunShellAndShow(command)
	local win, buf = get_term_win_in_tab()
	if not win then
		M.TermToggle()
		win, buf = get_term_win_in_tab()
	end
	if win and buf then
		local chan = vim.bo[buf].channel
		vim.api.nvim_chan_send(chan, command .. "\r")
		vim.api.nvim_set_current_win(win)
		vim.cmd("startinsert")
	end
end

function M.KillAndRerunTerm(name, command, opts)
	opts = vim.tbl_extend("force", { autoclose = false }, opts or {})
	local old_buf = get_term_by_name(name)
	if old_buf then
		vim.api.nvim_buf_delete(old_buf, { force = true })
	end
	local win = get_term_win_in_tab()
	if not win then
		GotoMainWindow()
		vim.cmd("leftabove split")
		vim.cmd("resize " .. math.floor(vim.o.lines * 0.4))
		win = vim.api.nvim_get_current_win()
	end
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(win, buf)
	setup_terminal_buffer(buf, name)
	table.insert(term_bufs, buf)
	last_active_idx = #term_bufs
	local cmd = type(command) == "table" and command or { "sh", "-c", command }
	vim.api.nvim_buf_call(buf, function()
		vim.fn.jobstart(cmd, {
			term = true,
			on_exit = function(_, code)
				vim.schedule(function()
					if opts.notify and vim.fn.executable("hterm-notify") == 1 then
						vim.system({ "hterm-notify", name, opts.notify .. " (exit " .. code .. ")" })
					end
					if opts.autoclose and vim.api.nvim_buf_is_valid(buf) then
						vim.api.nvim_buf_delete(buf, { force = true })
					end
				end)
			end,
		})
	end)
	vim.api.nvim_set_current_win(win)
	vim.cmd("startinsert")
end

function M.KillAndRerunTermWrapper(command, opts)
	M.KillAndRerunTerm(command:gsub(" ", "_"), command, opts)
end

function M.RunCurrentLine()
	local cmd = tostring(vim.api.nvim_get_current_line())
	M.KillAndRerunTermWrapper(cmd)
end

function M.FloatermNext(offset)
	local win, buf = get_term_win_in_tab()
	if not win then
		M.TermToggle()
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

M.get_window = get_term_win_in_tab
M.get_buffers = get_valid_term_bufs
M.index_of = indexOf
M.title = termTitle

for _, name in ipairs({
	"NativeTermSendTrimmed",
	"HasTerminal",
	"NewTerminal",
	"TermToggle",
	"AltDSwitch",
	"RunPreviousCommandFunc",
	"RunShellAndShow",
	"KillAndRerunTerm",
	"KillAndRerunTermWrapper",
	"RunCurrentLine",
	"FloatermNext",
}) do
	_G[name] = M[name]
end
return M
