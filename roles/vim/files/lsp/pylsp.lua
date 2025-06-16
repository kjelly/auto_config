return {
	settings = {
		pylsp = {
			configurationSources = { "flake8" },
			plugins = {
				autopep8 = { enabled = false },
				flake8 = { enabled = true },
				pycodestyle = { enabled = false },
				pylint = { enabled = false },
				pyflakes = { enabled = false },
				yapf = { enabled = false },
			},
		},
	},
}
