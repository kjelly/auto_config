return {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
	root_markers = { ".git" },
	settings = {
		redhat = { telemetry = { enabled = false } },
		schemas = {
			...,
			["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
			["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/v1.32.1-standalone-strict/all.json"] = "/*.k8s.yaml",
			["https://raw.githubusercontent.com/zarf-dev/zarf/main/zarf.schema.json"] = "zarf*.yaml",
		},
	},
}
