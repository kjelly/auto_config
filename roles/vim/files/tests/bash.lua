local bash = require("config.bash")

local checks = {}
local function check(name, fn)
	local ok, err = xpcall(fn, debug.traceback)
	checks[#checks + 1] = { name = name, ok = ok, error = not ok and err or nil }
end

-- 1. Test to_single_line basic backslash join
check("basic backslash continuation", function()
	local lines = {
		"docker run -d \\",
		"  --name web \\",
		"  -p 8080:80 \\",
		"  nginx:alpine",
	}
	local result = bash.to_single_line(lines)
	assert(result == "docker run -d --name web -p 8080:80 nginx:alpine", "got: " .. result)
end)

-- 2. Test trailing spaces after backslash
check("trailing spaces after backslash", function()
	local lines = {
		"docker run -d \\   ",
		"  --name web \\\t",
		"  nginx:alpine",
	}
	local result = bash.to_single_line(lines)
	assert(result == "docker run -d --name web nginx:alpine", "got: " .. result)
end)

-- 3. Test comment lines and blank lines in between
check("comments and blank lines ignored", function()
	local lines = {
		"docker run -d \\",
		"  # set the name",
		"  --name web \\",
		"",
		"  nginx:alpine",
	}
	local result = bash.to_single_line(lines)
	assert(result == "docker run -d --name web nginx:alpine", "got: " .. result)
end)

-- 4. Test pipe continuation
check("pipe continuation", function()
	local lines = {
		"cat access.log |",
		"  grep 404 |",
		"  wc -l",
	}
	local result = bash.to_single_line(lines)
	assert(result == "cat access.log | grep 404 | wc -l", "got: " .. result)
end)

-- 5. Test logical operator continuation
check("logical operators continuation", function()
	local lines = {
		"npm run build &&",
		"  npm test &&",
		"  npm run deploy",
	}
	local result = bash.to_single_line(lines)
	assert(result == "npm run build && npm test && npm run deploy", "got: " .. result)
end)

-- 6. Test separate commands default to &&
check("separate commands default to &&", function()
	local lines = {
		"git add .",
		"git commit -m 'update'",
		"git push",
	}
	local result = bash.to_single_line(lines)
	assert(result == "git add . && git commit -m 'update' && git push", "got: " .. result)
end)

-- 7. Test custom separators
check("custom separator ;", function()
	local lines = {
		"echo 1",
		"echo 2",
	}
	local result = bash.to_single_line(lines, ";")
	assert(result == "echo 1; echo 2", "got: " .. result)
end)

check("custom separator space", function()
	local lines = {
		"echo 1",
		"echo 2",
	}
	local result = bash.to_single_line(lines, "space")
	assert(result == "echo 1 echo 2", "got: " .. result)
end)

-- 8. Test escaped backslash (even count)
check("escaped double backslash preserved", function()
	local lines = {
		"echo foo\\\\",
		"echo bar",
	}
	local result = bash.to_single_line(lines, "&&")
	assert(result == "echo foo\\\\ && echo bar", "got: " .. result)
end)

-- 9. Test get_multiline_range
check("get_multiline_range boundary detection", function()
	local buf = vim.api.nvim_create_buf(false, true)
	local buffer_lines = {
		"# header comment",
		"echo 'before'",
		"docker run -d \\",
		"  # note",
		"  --name web \\",
		"  -p 8080:80 \\",
		"  nginx:alpine",
		"echo 'after'",
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, buffer_lines)

	-- Test from line 3 (start of continuation)
	local s, e = bash.get_multiline_range(buf, 3)
	assert(s == 3 and e == 7, string.format("from line 3 got s=%s, e=%s", tostring(s), tostring(e)))

	-- Test from line 5 (middle of continuation)
	s, e = bash.get_multiline_range(buf, 5)
	assert(s == 3 and e == 7, string.format("from line 5 got s=%s, e=%s", tostring(s), tostring(e)))

	-- Test from line 7 (terminal line)
	s, e = bash.get_multiline_range(buf, 7)
	assert(s == 3 and e == 7, string.format("from line 7 got s=%s, e=%s", tostring(s), tostring(e)))

	-- Test from line 2 (unrelated line)
	s, e = bash.get_multiline_range(buf, 2)
	assert(s == nil and e == nil, "unrelated line 2 should return nil")
end)

-- 10. Test buffer replacement and indentation preservation
check("buffer replacement with indent", function()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(buf)
	local buffer_lines = {
		"    docker run -d \\",
		"      --name web \\",
		"      nginx:alpine",
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, buffer_lines)
	vim.api.nvim_win_set_cursor(0, { 1, 4 })

	bash.bash_to_one_line({ range = 0 })

	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	assert(#lines == 1, "expected 1 line, got " .. #lines)
	assert(
		lines[1] == "    docker run -d --name web nginx:alpine",
		"expected indentation preserved, got: " .. lines[1]
	)
	assert(vim.fn.getreg('"') == "docker run -d --name web nginx:alpine", "register \" not set")
end)

-- 11. Test bash_copy_one_line (does not modify buffer)
check("bash_copy_one_line does not modify buffer", function()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(buf)
	local buffer_lines = {
		"docker run -d \\",
		"  --name web \\",
		"  nginx:alpine",
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, buffer_lines)
	vim.api.nvim_win_set_cursor(0, { 2, 0 })

	bash.bash_copy_one_line({ range = 0 })

	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	assert(#lines == 3, "buffer should not be modified, got line count: " .. #lines)
	assert(vim.fn.getreg("+") == "docker run -d --name web nginx:alpine", "clipboard not set")
end)

-- 12. Test bang (!) copies to clipboard during replacement
check("bash_to_one_line with bang copies to clipboard", function()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(buf)
	local buffer_lines = {
		"curl -X GET \\",
		"  https://example.com",
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, buffer_lines)
	vim.api.nvim_win_set_cursor(0, { 1, 0 })

	bash.bash_to_one_line({ range = 0, bang = true })

	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	assert(#lines == 1 and lines[1] == "curl -X GET https://example.com", "buffer replacement failed")
	assert(vim.fn.getreg("+") == "curl -X GET https://example.com", "clipboard + not set")
	assert(vim.fn.getreg("*") == "curl -X GET https://example.com", "primary * not set")
end)

-- 13. Test command execution via user command BashToOneLine and aliases
check("user command setup and execution", function()
	bash.setup()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(buf)
	local buffer_lines = {
		"git status",
		"git branch",
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, buffer_lines)

	-- Range execution: 1,2BashToOneLine
	vim.cmd("1,2BashToOneLine")
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	assert(#lines == 1 and lines[1] == "git status && git branch", "got: " .. vim.inspect(lines))

	-- Alias BashSingleLine with argument ;
	local buf2 = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(buf2)
	vim.api.nvim_buf_set_lines(buf2, 0, -1, false, { "echo a", "echo b" })
	vim.cmd("1,2BashSingleLine ;")
	lines = vim.api.nvim_buf_get_lines(buf2, 0, -1, false)
	assert(#lines == 1 and lines[1] == "echo a; echo b", "got: " .. vim.inspect(lines))

	-- Alias BashJoin
	local buf3 = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(buf3)
	vim.api.nvim_buf_set_lines(buf3, 0, -1, false, { "pytest \\", "  -v" })
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	vim.cmd("BashJoin")
	lines = vim.api.nvim_buf_get_lines(buf3, 0, -1, false)
	assert(#lines == 1 and lines[1] == "pytest -v", "got: " .. vim.inspect(lines))
end)

-- Output results
local failed = 0
for _, c in ipairs(checks) do
	if c.ok then
		print("PASS " .. c.name)
	else
		print("FAIL " .. c.name .. ": " .. tostring(c.error))
		failed = failed + 1
	end
end

if failed > 0 then
	error(string.format("%d checks failed", failed))
end
