return {
	"hrsh7th/nvim-cmp",
	event = { "InsertEnter", "CmdlineEnter" },
	dependencies = {
		{ "hrsh7th/cmp-nvim-lsp" },
		{ "hrsh7th/cmp-buffer" },
		{ "hrsh7th/cmp-path" },
		{ "lukas-reineke/cmp-rg" },
		{ "hrsh7th/cmp-nvim-lsp-document-symbol" },
		{ "hrsh7th/cmp-cmdline" },
	},
	config = function()
		local cmp = require("cmp")

		local cmp_sources = {
			{ name = "nvim_lsp", keyword_length = 0 },
			{ name = "path" },
			{
				name = "rg",
				max_item_count = 10,
				keyword_length = 5,
				option = { additional_arguments = "--max-depth 5" },
			},
			{ name = "buffer", keyword_length = 4 },
		}

		if cmp == nil then
			return
		end

		local has_words_before = function()
			if vim.bo[0].buftype == "prompt" then
				return false
			end
			local line, col = unpack(vim.api.nvim_win_get_cursor(0))
			return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
		end

		cmp.setup({
			preselect = cmp.PreselectMode.None,
			completion = {
				preselect = false,
			},
			snippet = {
				expand = function(args)
					vim.snippet.expand(args.body)
				end,
			},
			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},
			mapping = {
				["<Space>"] = cmp.mapping(function(fallback)
					if cmp.visible() and cmp.get_active_entry() then
						cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
					else
						fallback()
					end
				end, { "i", "s", "c" }),
				["<C-d>"] = cmp.mapping.scroll_docs(5),
				["<C-u>"] = cmp.mapping.scroll_docs(-5),
				["<C-g>"] = cmp.mapping(function(fallback)
					if vim.snippet.active({ direction = -1 }) then
						vim.snippet.jump(-1)
					else
						fallback()
					end
				end, { "i", "s" }),
				["<C-f>"] = cmp.mapping(function(fallback)
					if vim.snippet.active({ direction = 1 }) then
						vim.snippet.jump(1)
					elseif has_words_before() then
						cmp.complete()
					else
						fallback()
					end
				end, { "i", "s" }),
				["<m-/>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
				["<C-n>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
					else
						cmp.complete()
					end
				end),
				["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
				["<CR>"] = cmp.mapping(function(fallback)
					if cmp.visible() and cmp.get_active_entry() then
						cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
					else
						fallback()
					end
				end, { "i", "s", "c" }),
			},
			sources = cmp.config.sources(cmp_sources),
			sorting = {
				priority_weight = 2,
				comparators = {
					cmp.config.compare.offset,
					cmp.config.compare.exact,
					cmp.config.compare.score,
					cmp.config.compare.recently_used,
					cmp.config.compare.locality,
					cmp.config.compare.kind,
					cmp.config.compare.sort_text,
					cmp.config.compare.length,
					cmp.config.compare.order,
				},
			},
		})

		local search_sources = {
			{ name = "nvim_lsp_document_symbol" },
			{ name = "buffer" },
		}
		local function setup_cmdline(cmd_type, sources)
			cmp.setup.cmdline(cmd_type, {
				mapping = cmp.mapping.preset.cmdline({
					["<C-n>"] = {
						c = function(fallback)
							if cmp.visible() then
								cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
							else
								fallback()
							end
						end,
					},
					["<C-p>"] = {
						c = function(fallback)
							if cmp.visible() then
								cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
							else
								fallback()
							end
						end,
					},
					["<Down>"] = {
						c = function(fallback)
							if cmp.visible() then
								cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
							else
								fallback()
							end
						end,
					},
					["<Up>"] = {
						c = function(fallback)
							if cmp.visible() then
								cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
							else
								fallback()
							end
						end,
					},
				}),
				view = { entries = { name = "custom", selection_order = "near_cursor" } },
				sources = sources,
			})
		end

		setup_cmdline("/", search_sources)
		setup_cmdline("?", search_sources)
		setup_cmdline(":", {
			{ name = "path" },
			{ name = "cmdline" },
		})
	end,
}
