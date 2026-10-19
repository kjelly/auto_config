local M = {}

function M.setup()
	local group = vim.api.nvim_create_augroup("ConfigEvents", { clear = true })
	local session_dir = vim.fn.stdpath("state") .. "/sessions/"
	vim.fn.mkdir(session_dir, "p")
	local function session_file()
		return session_dir .. vim.fn.getcwd():gsub("%%", "%%25"):gsub("/", "%%") .. ".vim"
	end
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			-- One-file invocations and headless checks must not replace project sessions.
			if #vim.api.nvim_list_uis() == 0 or vim.fn.argc() > 0 then
				return
			end
			if #vim.fn.getbufinfo({ buflisted = 1 }) > 0 then
				vim.cmd("silent mksession! " .. vim.fn.fnameescape(session_file()))
			end
		end,
	})
	vim.keymap.set("n", "<leader>qs", function()
		local file = session_file()
		if vim.fn.filereadable(file) == 1 then
			vim.cmd.source(file)
		else
			vim.notify("No session saved for this directory")
		end
	end, { desc = "Restore session" })
	vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
		group = group,
		callback = function()
			if vim.fn.mode() ~= "c" then
				vim.cmd("checktime")
			end
		end,
	})
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		callback = function()
			vim.wo.cursorline = vim.fn.mode() == "n"
		end,
	})
	vim.diagnostic.config({
		virtual_text = { source = true, severity = { min = vim.diagnostic.severity.INFO } },
		float = { source = true },
		update_in_insert = false,
	})
	vim.on_key(function(char)
		if vim.fn.mode() == "n" then
			vim.opt.hlsearch = vim.tbl_contains({ "n", "N", "*", "#", "?", "/" }, vim.fn.keytrans(char))
		end
	end, vim.api.nvim_create_namespace("auto_hlsearch"))
	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function()
			vim.o.titlestring = vim.env.TMUX and (vim.fn.getcwd():gsub("%%", "%%%%") .. " > vim")
				or ("@" .. vim.fn.hostname() .. " %t")
		end,
	})
	local ns = vim.api.nvim_create_namespace("my.terminal.prompt")
	vim.api.nvim_create_autocmd("TermRequest", {
		group = group,
		callback = function(args)
			if args.data.sequence:match("^\027]133;A") then
				vim.api.nvim_buf_set_extmark(
					args.buf,
					ns,
					args.data.cursor[1] - 1,
					0,
					{ sign_text = "▶", sign_hl_group = "SpecialChar" }
				)
			end
		end,
	})
	for _, mode in ipairs({ "i", "n", "t" }) do
		vim.keymap.set(mode, "<m-g>", WinPick, { desc = "Move to Window" })
	end
	vim.keymap.set("n", "]x", "/^<<<<<<<\\|^=======\\|^>>>>>>>/e<CR>", { silent = true, desc = "Next Git conflict" })
	vim.keymap.set(
		"n",
		"[x",
		"?^<<<<<<<\\|^=======\\|^>>>>>>>?e<CR>",
		{ silent = true, desc = "Previous Git conflict" }
	)
	vim.schedule(function()
		UpdateEnv()
		if FileExists(WorkspaceVimPath) then
			vim.cmd.source(WorkspaceVimPath)
		end
	end)
end

return M
