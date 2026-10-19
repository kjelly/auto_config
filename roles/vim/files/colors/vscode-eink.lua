-- vscode-eink: a vscode.nvim based colorscheme.
--   * background=dark  -> identical to the stock `vscode` dark theme.
--   * background=light -> a high-contrast grayscale variant tuned for e-ink
--     screens, where hues collapse into indistinguishable grays. Syntax is
--     differentiated by lightness + bold/italic instead of color.
--
-- Neovim re-sources the active colorscheme whenever 'background' changes, so
-- toggling `vim.o.background` flips between the two variants automatically.

local vscode = require("vscode")

if vim.o.background == "dark" then
	-- Dark: leave the stock vscode theme untouched. We still call setup() to
	-- clear any light-mode overrides that may linger from a previous toggle
	-- (config.opts is a shared global inside the plugin).
	vscode.setup({ color_overrides = {}, group_overrides = {} })
	vscode.load()
else
	-- Light / e-ink. On grayscale e-ink the perceived value is what matters:
	-- keep body text near-black for contrast, and space the accent grays far
	-- enough apart (>= ~0x20) that they remain distinguishable as gray levels.
	vscode.setup({
		italic_comments = true,
		color_overrides = {
			vscFront = "#000000",
			vscBack = "#FFFFFF",
			vscGray = "#000000",
			vscBlue = "#000000",
			vscPink = "#000000",
			vscViolet = "#000000",
			vscYellow = "#1C1C1C",
			vscOrange = "#4C4C4C",
			vscLightGreen = "#3A3A3A",
			vscGreen = "#6B6B6B",
			vscBlueGreen = "#2B2B2B",
			vscYellowOrange = "#2E2E2E",
			vscDarkBlue = "#2B2B2B",
			vscLightBlue = "#1C1C1C",

			vscLineNumber = "#808080",
			vscSelection = "#C8C8C8",
			vscSearch = "#C4C4C4",
			vscSearchCurrent = "#9E9E9E",
			vscSuggestion = "#8A8A8A",
			vscCursorLight = "#000000",

			vscDiffGreenDark = "#E3E3E3",
			vscDiffGreenLight = "#CFCFCF",
			vscDiffRedDark = "#C9C9C9",
			vscDiffRedLight = "#ACACAC",
			vscDiffRedLightLight = "#9E9E9E",

			vscGitAdded = "#4A4A4A",
			vscGitModified = "#6E6E6E",
			vscGitDeleted = "#000000",
			vscGitRenamed = "#4A4A4A",
			vscGitUntracked = "#4A4A4A",
			vscGitConflicting = "#000000",
		},
	})
	vscode.load()

	-- Add a second differentiating dimension (font style) on top of the grays,
	-- since e-ink flattens color. Merge weights onto the existing highlights so
	-- foreground colors set above are preserved.
	local function add_style(groups, style)
		for _, name in ipairs(groups) do
			local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
			if ok and next(hl) ~= nil then
				for k, v in pairs(style) do
					hl[k] = v
				end
				vim.api.nvim_set_hl(0, name, hl)
			end
		end
	end

	add_style({
		"Keyword",
		"Statement",
		"Conditional",
		"Repeat",
		"Exception",
		"@keyword",
		"@keyword.function",
		"@keyword.return",
		"@keyword.operator",
		"@conditional",
		"@repeat",
		"@exception",
		"Function",
		"@function",
		"@function.builtin",
		"@function.call",
		"@function.method",
		"Title",
		"@markup.heading",
	}, { bold = true })

	-- Keep render-markdown headings readable on e-ink displays.
	local heading_bg = { "#D0D0D0", "#D8D8D8", "#E0E0E0", "#E6E6E6", "#ECECEC", "#F0F0F0" }
	for i = 1, 6 do
		vim.api.nvim_set_hl(0, "@markup.heading." .. i .. ".markdown", { fg = "#000000", bold = true })
		vim.api.nvim_set_hl(0, "RenderMarkdownH" .. i, { fg = "#000000", bold = true })
		vim.api.nvim_set_hl(0, "RenderMarkdownH" .. i .. "Bg", { bg = heading_bg[i], bold = true })
	end
end

vim.g.colors_name = "vscode-eink"
