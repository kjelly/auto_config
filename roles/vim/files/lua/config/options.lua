vim.g.mapleader = ","
vim.g.maplocalleader = " "
vim.g.editconfig = true
vim.g.ollama_agent_model = "gemma4:12b"

local options = {
	termguicolors = true,
	guicursor = "a:block-blinkon0",
	splitkeep = "screen",
	title = true,
	number = true,
	keywordprg = "sdcvh.sh",
	cursorline = true,
	showcmd = true,
	mouse = "a",
	fileformats = { "unix", "dos", "mac" },
	shada = "'10,<800,h",
	showtabline = 0,
	undofile = true,
	scrolloff = 7,
	wildignore = { "*.o", "*~", "*.pyc" },
	cmdheight = 1,
	smartcase = true,
	showmatch = true,
	matchtime = 2,
	expandtab = true,
	shiftwidth = 2,
	tabstop = 2,
	linebreak = true,
	textwidth = 500,
	smartindent = true,
	wrap = true,
	laststatus = 3,
	timeoutlen = 500,
	updatetime = 300,
	completeopt = { "menuone", "noselect" },
	listchars = { tab = "► ", trail = "~", extends = ">", precedes = "<" },
	list = true,
	sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "globals" },
	shortmess = "sTWAIF",
	signcolumn = "yes",
	showmode = false,
	spell = true,
	spelloptions = "camel",
	inccommand = "split",
	winblend = 0,
	pumblend = 0,
	autoread = true,
	foldlevel = 99,
	foldtext = "",
	foldcolumn = "0",
}
for name, value in pairs(options) do
	vim.opt[name] = value
end
vim.opt.fillchars:append({ fold = " " })

local state = vim.fn.stdpath("state")
for option, directory in pairs({ directory = state .. "/swap//", undodir = state .. "/undo//" }) do
	vim.fn.mkdir(directory, "p")
	vim.opt[option] = directory
end

-- Filters use POSIX syntax. Interactive terminals select nu separately.
vim.o.shell = vim.fn.exepath("bash") ~= "" and vim.fn.exepath("bash") or "sh"
vim.o.shellcmdflag = "-c"
vim.o.shellquote = ""
vim.o.shellxquote = ""
if vim.fn.executable("rg") == 1 then
	vim.o.grepprg = "rg --vimgrep"
end
vim.env.IN_VIM = "1"
vim.g.MYVIMRC_DIR = vim.fn.stdpath("config")
vim.env.PATH = vim.env.PATH .. ":" .. vim.fn.stdpath("config") .. "/bin"
vim.g.qs_highlight_on_keys = { "f", "F", "t", "T" }

local osc52 = require("vim.ui.clipboard.osc52")
vim.g.clipboard = {
	name = "OSC 52",
	copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
	paste = { ["+"] = osc52.paste("+"), ["*"] = osc52.paste("*") },
}

-- Register custom types before the first buffer is read.
vim.filetype.add({
	pattern = {
		[".*/%.github/workflows/.*%.ya?ml"] = { "yaml.github", { priority = 20 } },
		[".*/tasks/.*%.ya?ml"] = { "yaml.ansible", { priority = 10 } },
	},
})
