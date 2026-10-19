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

local command = { "tmux", "display-message", "-p", "#{client_width}\t#{@eink-widths}" }

local function apply_result(result)
	if result.code ~= 0 then
		return
	end
	local width, raw = (result.stdout or ""):match("^(%d+)\t([^\r\n]*)")
	if width then
		vim.o.background = M.is_light_width(width, M.parse_widths(raw)) and "light" or "dark"
	end
end

function M.apply()
	if not vim.env.TMUX or vim.fn.executable("tmux") == 0 then
		return
	end
	local ok, result = pcall(function()
		return vim.system(command, { text = true }):wait(200)
	end)
	if ok then
		apply_result(result)
	end
end

local generation = 0
function M.refresh()
	if not vim.env.TMUX or vim.fn.executable("tmux") == 0 then
		return
	end
	generation = generation + 1
	local current = generation
	vim.system(
		command,
		{ text = true, timeout = 200 },
		vim.schedule_wrap(function(result)
			if current == generation then
				apply_result(result)
			end
		end)
	)
end

return M
