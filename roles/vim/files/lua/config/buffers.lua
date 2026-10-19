local M = {}

function M.close(force)
	local current = vim.api.nvim_get_current_buf()
	if vim.bo[current].modified and not force then
		error("Buffer has unsaved changes; write it first or use :Bclose!")
	end
	local replacement = vim.fn.bufnr("#")
	if replacement == current or not vim.api.nvim_buf_is_valid(replacement) or not vim.bo[replacement].buflisted then
		replacement = nil
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if buf ~= current and vim.bo[buf].buflisted then
				replacement = buf
				break
			end
		end
	end
	if not replacement then
		replacement = vim.api.nvim_create_buf(true, false)
	end
	for _, win in ipairs(vim.fn.win_findbuf(current)) do
		vim.api.nvim_win_set_buf(win, replacement)
	end
	vim.api.nvim_buf_delete(current, { force = force or false })
end

return M
