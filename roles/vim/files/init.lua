vim.loader.enable()

-- Local overrides contain machine-specific settings; credentials come from the environment.
local custom = vim.fn.expand("~/.vim_custom.vim")
if vim.fn.filereadable(custom) == 1 then
	vim.cmd.source(custom)
end
require("config.options")
require("config.theme").setup()
require("config.terminal")
require("config.actions")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	local output = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("Failed to install lazy.nvim: " .. output)
	end
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup(require("config.plugins"), {})
vim.cmd.source(vim.fn.stdpath("config") .. "/nvim.vim")
require("config.autocmds").setup()
require("config.gamepad").setup()
