local M = {}

function M.transparent()
	for _, group in ipairs({ "Normal", "NormalFloat", "SignColumn", "LineNr", "Folded", "NonText", "NormalNC" }) do
		local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
		hl.bg = nil
		vim.api.nvim_set_hl(0, group, hl)
	end
	if vim.o.background == "light" then
		for name, override in pairs({
			Comment = { fg = "#333333", italic = true, bold = true },
			LineNr = { fg = "#444444", bold = true },
		}) do
			local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
			vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", hl, override))
		end
	end
end

function M.setup()
	require("eink_theme").apply()
	local group = vim.api.nvim_create_augroup("ConfigTheme", { clear = true })
	vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter", "UIEnter" }, {
		group = group,
		callback = function()
			vim.schedule(M.transparent)
		end,
	})
	vim.api.nvim_create_autocmd("VimResized", {
		group = group,
		callback = function()
			require("eink_theme").refresh()
		end,
	})
end

return M
