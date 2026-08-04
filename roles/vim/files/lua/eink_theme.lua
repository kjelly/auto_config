local M = {}

local defaults = { [167] = true, [165] = true }

function M.parse_widths(raw)
	local widths = {}
	for field in tostring(raw or ""):gmatch("[^,]+") do
		local width = tonumber(vim.trim(field))
		if width and width > 0 and width % 1 == 0 then
			widths[width] = true
		end
	end
	return next(widths) and widths or vim.deepcopy(defaults)
end

function M.is_light_width(width, widths)
	return widths[tonumber(width)] == true
end

local function tmux_output(args)
	if not vim.env.TMUX then
		return nil
	end
	local command = vim.list_extend({ "tmux" }, args)
	local result = vim.system(command, { text = true }):wait()
	if result.code ~= 0 then
		return nil
	end
	return vim.trim(result.stdout or "")
end

function M.apply()
	local raw = tmux_output({ "show-options", "-gv", "@eink-widths" })
	local width = tmux_output({ "display-message", "-p", "#{client_width}" })
	vim.o.background = M.is_light_width(width, M.parse_widths(raw)) and "light" or "dark"
end

return M
