local M = {}

-- Check if a line is a comment or blank
local function is_ignorable(line)
	return line:match("^%s*$") ~= nil or line:match("^%s*#") ~= nil
end

-- Check if a line has an odd number of trailing backslashes (line continuation)
local function ends_with_backslash(line)
	if not line then
		return false
	end
	local bs = line:match("(\\+)%s*$")
	return bs ~= nil and (#bs % 2) == 1
end

-- Check if a line ends with a continuation operator (backslash, |, ||, &&)
local function ends_with_continuation(line)
	if not line then
		return false
	end
	if ends_with_backslash(line) then
		return true
	end
	local trimmed = line:gsub("%s+$", "")
	if trimmed:match("&&$") or trimmed:match("||$") then
		return true
	end
	-- Single pipe '|' (not '||')
	if trimmed:match("|$") and not trimmed:match("||$") then
		return true
	end
	return false
end

-- Remove continuation backslash at end of line (if odd) and trim whitespace
local function strip_trailing_continuation(line)
	local trimmed = line:gsub("%s+$", "")
	local bs = trimmed:match("(\\+)$")
	if bs and (#bs % 2) == 1 then
		trimmed = trimmed:sub(1, #trimmed - 1):gsub("%s+$", "")
	end
	return trimmed
end

-- Find boundaries of multiline bash command around cursor_line in normal mode
function M.get_multiline_range(bufnr, cursor_line)
	bufnr = bufnr or 0
	local total = vim.api.nvim_buf_line_count(bufnr)
	if total == 0 then
		return nil, nil
	end

	local function get_line(lnum)
		if lnum < 1 or lnum > total then
			return ""
		end
		return vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
	end

	cursor_line = math.max(1, math.min(cursor_line, total))
	local cur = get_line(cursor_line)

	-- Check if cursor_line itself or previous line ends with continuation
	local is_part = false
	if ends_with_continuation(cur) then
		is_part = true
	else
		-- Check backwards past ignorable lines
		for k = cursor_line - 1, 1, -1 do
			local k_line = get_line(k)
			if not is_ignorable(k_line) then
				if ends_with_continuation(k_line) then
					is_part = true
				end
				break
			end
		end
	end

	if not is_part then
		return nil, nil
	end

	-- Scan backwards to find start_line
	local start_line = cursor_line
	while start_line > 1 do
		local prev = get_line(start_line - 1)
		if is_ignorable(prev) then
			local found_above = false
			for k = start_line - 2, 1, -1 do
				local k_line = get_line(k)
				if not is_ignorable(k_line) then
					if ends_with_continuation(k_line) then
						found_above = true
					end
					break
				end
			end
			if found_above then
				start_line = start_line - 1
			else
				break
			end
		elseif ends_with_continuation(prev) then
			start_line = start_line - 1
		else
			break
		end
	end

	-- Scan forwards to find end_line
	local end_line = start_line
	while end_line < total do
		local current = get_line(end_line)
		if ends_with_continuation(current) then
			end_line = end_line + 1
		elseif is_ignorable(current) then
			local found_below = false
			for k = end_line + 1, total do
				local k_line = get_line(k)
				if not is_ignorable(k_line) then
					found_below = true
					break
				end
			end
			if found_below then
				end_line = end_line + 1
			else
				break
			end
		else
			-- Current line does not end with continuation: this is the terminal line!
			break
		end
	end

	return start_line, end_line
end

-- Convert a list of lines into a single line string
function M.to_single_line(lines, sep_arg)
	local cleaned = {}
	local had_continuation = false

	for _, line in ipairs(lines) do
		if ends_with_continuation(line) then
			had_continuation = true
		end

		if not is_ignorable(line) then
			local trimmed_left = line:gsub("^%s+", "")
			local stripped = strip_trailing_continuation(trimmed_left)
			if stripped ~= "" then
				table.insert(cleaned, stripped)
			end
		end
	end

	if #cleaned == 0 then
		return ""
	end

	local sep = sep_arg and vim.trim(sep_arg) or ""
	if sep ~= "" then
		if sep == "space" then
			sep = " "
		elseif sep == "&&" then
			sep = " && "
		elseif sep == ";" then
			sep = "; "
		elseif sep == "||" then
			sep = " || "
		elseif sep == "|" then
			sep = " | "
		else
			if not sep:match("^%s") then
				sep = " " .. sep
			end
			if not sep:match("%s$") then
				sep = sep .. " "
			end
		end
	else
		if had_continuation then
			sep = " "
		else
			sep = " && "
		end
	end

	return table.concat(cleaned, sep)
end

-- Resolve the range of lines to operate on
local function resolve_range(opts)
	local bufnr = vim.api.nvim_get_current_buf()
	local line1, line2

	if opts and opts.range and opts.range > 0 then
		line1 = opts.line1
		line2 = opts.line2
	else
		local cur = vim.api.nvim_win_get_cursor(0)[1]
		local s, e = M.get_multiline_range(bufnr, cur)
		if s and e then
			line1, line2 = s, e
		else
			return nil, nil, bufnr
		end
	end

	return line1, line2, bufnr
end

-- Convert multiline bash command to single line in the buffer
function M.bash_to_one_line(opts)
	opts = opts or {}
	local line1, line2, bufnr = resolve_range(opts)

	if not line1 or not line2 then
		vim.notify(
			"Cursor is not on a multiline bash command (lines ending with \\, |, &&, ||).\n"
				.. "Tip: Select lines in visual mode to join them.",
			vim.log.levels.WARN
		)
		return
	end

	local raw_lines = vim.api.nvim_buf_get_lines(bufnr, line1 - 1, line2, false)
	if #raw_lines == 0 then
		return
	end

	local single_line = M.to_single_line(raw_lines, opts.args)
	if single_line == "" then
		vim.notify("No command found in the specified range.", vim.log.levels.WARN)
		return
	end

	-- Preserve leading indentation of the first non-ignorable line
	local indent = ""
	for _, l in ipairs(raw_lines) do
		if not is_ignorable(l) then
			indent = l:match("^(%s*)") or ""
			break
		end
	end

	local replaced_line = indent .. single_line
	vim.api.nvim_buf_set_lines(bufnr, line1 - 1, line2, false, { replaced_line })

	-- Set unnamed register for quick pasting
	vim.fn.setreg('"', single_line)

	-- If bang (!) was given, also copy to clipboard
	local msg_suffix = ""
	if opts.bang then
		vim.fn.setreg("+", single_line)
		vim.fn.setreg("*", single_line)
		msg_suffix = " (copied to clipboard)"
	end

	-- Move cursor to the beginning of the joined command
	pcall(vim.api.nvim_win_set_cursor, 0, { line1, #indent })

	vim.notify(
		string.format("Joined %d lines into single line command%s", #raw_lines, msg_suffix),
		vim.log.levels.INFO
	)
end

-- Copy multiline bash command as single line without modifying the buffer
function M.bash_copy_one_line(opts)
	opts = opts or {}
	local line1, line2, bufnr = resolve_range(opts)

	if not line1 or not line2 then
		vim.notify(
			"Cursor is not on a multiline bash command (lines ending with \\, |, &&, ||).\n"
				.. "Tip: Select lines in visual mode to copy them.",
			vim.log.levels.WARN
		)
		return
	end

	local raw_lines = vim.api.nvim_buf_get_lines(bufnr, line1 - 1, line2, false)
	local single_line = M.to_single_line(raw_lines, opts.args)
	if single_line == "" then
		vim.notify("No command found in the specified range.", vim.log.levels.WARN)
		return
	end

	vim.fn.setreg("+", single_line)
	vim.fn.setreg("*", single_line)
	vim.fn.setreg('"', single_line)

	vim.notify("Copied single line command to clipboard: " .. single_line, vim.log.levels.INFO)
end

function M.setup()
	local command_opts = {
		range = true,
		bang = true,
		nargs = "?",
		desc = "Convert multiline bash command to single line",
	}

	vim.api.nvim_create_user_command("BashToOneLine", function(opts)
		M.bash_to_one_line(opts)
	end, command_opts)

	vim.api.nvim_create_user_command("BashSingleLine", function(opts)
		M.bash_to_one_line(opts)
	end, command_opts)

	vim.api.nvim_create_user_command("BashJoin", function(opts)
		M.bash_to_one_line(opts)
	end, command_opts)

	vim.api.nvim_create_user_command("BashCopyOneLine", function(opts)
		M.bash_copy_one_line(opts)
	end, {
		range = true,
		nargs = "?",
		desc = "Copy multiline bash command as single line to clipboard without modifying buffer",
	})

	vim.api.nvim_create_user_command("BashYankOneLine", function(opts)
		M.bash_copy_one_line(opts)
	end, {
		range = true,
		nargs = "?",
		desc = "Copy multiline bash command as single line to clipboard without modifying buffer",
	})

	-- Keymaps
	-- Normal mode: operates on detected multiline command block under cursor
	vim.keymap.set("n", "<leader>bj", "<cmd>BashToOneLine<CR>", {
		desc = "Bash: join multiline to single line",
		silent = true,
	})
	vim.keymap.set("n", "<leader>by", "<cmd>BashCopyOneLine<CR>", {
		desc = "Bash: copy multiline as single line",
		silent = true,
	})

	-- Visual mode: operates on visually selected lines
	vim.keymap.set("v", "<leader>bj", ":BashToOneLine<CR>", {
		desc = "Bash: join multiline to single line",
		silent = true,
	})
	vim.keymap.set("v", "<leader>by", ":BashCopyOneLine<CR>", {
		desc = "Bash: copy multiline as single line",
		silent = true,
	})
end

return M
