-- Run through tests/run.sh. Installs, real LSP processes and local overrides are isolated.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local plugin_root = vim.fn.stdpath("data") .. "/lazy"
vim.opt.rtp:prepend(root)
vim.go.loadplugins = true
vim.cmd("filetype plugin indent on")
local source = vim.cmd.source
vim.cmd.source = function(path)
	if path == vim.fn.expand("~/.vim_custom.vim") then
		return
	end
	return source(path)
end
-- The sandbox prohibits Unix sockets; pickers need the name but are not opened in checks.
vim.fn.serverstart = function()
	return vim.fn.stdpath("state") .. "/mock-server"
end
vim.opt.rtp:prepend(plugin_root .. "/lazy.nvim")
local lazy = require("lazy")
local setup = lazy.setup
lazy.setup = function(spec, opts)
	opts.install = { missing = false }
	opts.checker = { enabled = false }
	opts.change_detection = { enabled = false }
	opts.local_spec = false
	opts.lockfile = vim.fn.stdpath("state") .. "/test-lock.json"
	local result = setup(spec, opts)
	if vim.env.NVIM_TEST_PARSER_DIR then
		vim.opt.rtp:prepend(vim.env.NVIM_TEST_PARSER_DIR)
	end
	return result
end
vim.opt.rtp:prepend(plugin_root .. "/mason.nvim")
local registry = require("mason-registry")
registry.refresh = function() end
local get = registry.get_package
registry.get_package = function(name)
	local pkg = get(name)
	pkg.install = function()
		error("Unexpected install in test: " .. name)
	end
	return pkg
end
_G.test_enabled_servers = {}
vim.lsp.enable = function(names)
	vim.list_extend(_G.test_enabled_servers, type(names) == "table" and names or { names })
end

dofile(root .. "/init.lua")
FileExists = function()
	return false
end
local checks = {}
local function check(name, fn)
	local ok, err = xpcall(fn, debug.traceback)
	checks[#checks + 1] = { name = name, ok = ok, error = not ok and err or nil }
end
check("no startup errors", function()
	assert(vim.v.errmsg == "", vim.v.errmsg)
end)
check("removed plugins absent", function()
	local plugins = require("lazy.core.config").plugins
	for _, name in ipairs({
		"blink.cmp",
		"telescope.nvim",
		"nvim-navic",
		"hlargs.nvim",
		"lush.nvim",
		"mini.indentscope",
		"vscode-eink.nvim",
	}) do
		assert(not plugins[name], name)
	end
	assert(plugins["nvim-cmp"])
end)
check("load configured features", function()
	require("lazy").load({
		plugins = {
			"mason-lspconfig.nvim",
			"nvim-cmp",
			"conform.nvim",
			"noice.nvim",
			"lualine.nvim",
			"codecompanion.nvim",
			"nvim-dap-ui",
		},
	})
end)
check("YAML filetypes and settings", function()
	local yaml = vim.lsp.config.yamlls
	assert(yaml.settings.yaml.schemas and not yaml.settings.schemas)
	assert(vim.tbl_contains(yaml.filetypes, "yaml.github"))
	assert(vim.tbl_contains(yaml.filetypes, "yaml.ansible"))
	assert(vim.filetype.match({ filename = "/tmp/project/.github/workflows/ci.yml" }) == "yaml.github")
	assert(vim.filetype.match({ filename = "/tmp/project/tasks/main.yaml" }) == "yaml.ansible")
end)
check("Mason only enables configured servers", function()
	assert(require("mason-lspconfig.settings").current.automatic_enable == false)
	for _, name in ipairs(test_enabled_servers) do
		assert(vim.lsp.config[name] and vim.lsp.config[name].cmd, name)
	end
	assert(vim.lsp.config.lua_ls.cmd[1] == "lua-language-server")
end)
check("completion uses cmp and native snippets", function()
	assert(package.loaded.cmp)
	assert(not package.loaded["blink.cmp"])
	local config = require("cmp").get_config()
	assert(config.snippet.expand)
end)
check("keymap targets and manual formatter", function()
	for _, key in ipairs({ "[d", "]d" }) do
		assert(not vim.fn.maparg(key, "n"):find("severity"), key)
	end
	assert(vim.fn.maparg(",lf", "n"):find("conform"))
	assert(vim.fn.maparg(",lf", "x"):find("conform"))
	assert(vim.fn.maparg(",rr", "n"):find("command_history"))
	assert(vim.fn.maparg(" a", "n"):find("live_grep"))
	assert(vim.fn.maparg(".", "n") == "")
	assert(vim.fn.maparg(",zf", "n") ~= "")
end)
check("transparent theme preserves text foreground", function()
	for _, bg in ipairs({ "light", "dark" }) do
		vim.o.background = bg
		vim.cmd.colorscheme("vscode-eink")
		local before = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
		require("config.theme").transparent()
		local after = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
		assert(before.fg and after.fg == before.fg)
		assert(after.bg == nil)
	end
end)
check("Bclose protects changes and preserves windows", function()
	vim.cmd("enew!")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unsaved" })
	local original = vim.api.nvim_get_current_buf()
	local windows = #vim.api.nvim_list_wins()
	local ok = pcall(vim.cmd, "Bclose")
	assert(not ok)
	assert(vim.api.nvim_get_current_buf() == original and vim.bo[original].modified)
	vim.cmd("Bclose!")
	assert(not vim.api.nvim_buf_is_loaded(original))
	assert(#vim.api.nvim_list_wins() == windows)
	vim.v.errmsg = ""
end)
check("Treesitter handles parser availability", function()
	vim.cmd("enew!")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "def example():", "    return True" })
	vim.bo.filetype = "python"
	local parser = assert(vim.treesitter.get_parser(0, "python"))
	if parser then
		assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()])
		assert(vim.bo.indentexpr:find("nvim%-treesitter"))
	end
	vim.cmd("enew!")
	vim.bo.filetype = "lua"
	assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()])
	assert(vim.bo.indentexpr:find("nvim%-treesitter"))
end)

check("signature handler is registered once per buffer", function()
	local buf = vim.api.nvim_get_current_buf()
	local hooks = vim.api.nvim_get_autocmds({ group = "ConfigLsp", event = "LspAttach" })
	assert(#hooks == 1)
	hooks[1].callback({ buf = buf })
	hooks[1].callback({ buf = buf })
	assert(#vim.api.nvim_get_autocmds({ group = "ConfigLsp", event = "CursorHoldI", buffer = buf }) == 1)
end)
check("Conform formats Lua with the installed formatter", function()
	vim.cmd("enew!")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x={a=1}" })
	vim.bo.filetype = "lua"
	require("conform").format({ async = false, lsp_format = "fallback", timeout_ms = 2000 })
	assert(vim.api.nvim_get_current_line():find("local x =", 1, true))
	vim.bo.modified = false
end)
check("installed parser queries are compatible", function()
	local count = 0
	for _, path in ipairs(vim.api.nvim_get_runtime_file("parser/*.so", true)) do
		local lang = vim.fn.fnamemodify(path, ":t:r")
		assert(vim.treesitter.language.add(lang))
		for _, query in ipairs({ "highlights", "indents", "folds" }) do
			vim.treesitter.query.get(lang, query)
		end
		count = count + 1
	end
	assert(count >= 31, "configured parsers are not installed")
end)
check("terminal preserves failures, quoting and wrapper options", function()
	vim.cmd("enew!")
	local term = require("config.terminal")
	term.KillAndRerunTerm("test-failure", [[printf '%s\n' 'a "quoted" value'; exit 7]], { shell = true })
	local buf = vim.api.nvim_get_current_buf()
	local code = vim.fn.jobwait({ vim.bo[buf].channel }, 3000)[1]
	vim.wait(100, function()
		return false
	end, 10)
	assert(code == 7 and vim.api.nvim_buf_is_valid(buf))
	assert(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"):find('a "quoted" value', 1, true))
	term.KillAndRerunTerm("test-success", { "sh", "-c", "exit 0" })
	buf = vim.api.nvim_get_current_buf()
	assert(vim.fn.jobwait({ vim.bo[buf].channel }, 3000)[1] == 0)
	vim.wait(100, function()
		return false
	end, 10)
	assert(not vim.api.nvim_buf_is_valid(buf))
	term.KillAndRerunTermWrapper("exit 8", { autoclose = true })
	buf = vim.api.nvim_get_current_buf()
	vim.fn.jobwait({ vim.bo[buf].channel }, 3000)
	vim.wait(100, function()
		return false
	end, 10)
	assert(not vim.api.nvim_buf_is_valid(buf))
end)
vim.wait(300, function()
	return false
end, 10)
check("no deferred errors", function()
	assert(vim.v.errmsg == "", vim.v.errmsg)
	local messages = vim.api.nvim_exec2("messages", { output = true }).output
	assert(not messages:find("Failed to run"), messages)
end)
local failed = 0
for _, result in ipairs(checks) do
	io.stdout:write((result.ok and "PASS " or "FAIL ") .. result.name .. "\n")
	if not result.ok then
		failed = failed + 1
		io.stdout:write(result.error .. "\n")
	end
end
io.stdout:flush()
vim.cmd(failed == 0 and "noautocmd qa!" or "noautocmd cquit")
