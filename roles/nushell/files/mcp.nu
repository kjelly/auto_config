def mcp-ssh-host [ ] {
  carapace ssh nushell ""|from json|get value|where {|it| "|" not-in $it}
}


let mcphost_common_config = {
  "temperature": 0.0,
  "top-p": 0.1,
  "top-k": 2,
  "stream": false,
  "debug": false,
  "model": "ollama:gpt-oss",
  "max-tokens": 18192,
  "system-prompt": "You are a helpful assistant. Please helm me find some informaiton or error by tools.\nTry hard to find more informaiton if possible.\nRun the command
if possible\nCall another tools if needed.\nAnalysis the response. Output format: title, fact, explain, action, summary."
  mcpServers: []
}


def mcp-ssh [ host:string@mcp-ssh-host ] {
  let mcp_ssh_server = {
    "target": {
      "command": "mcp-ssh-server",
      "args": [
        $host
      ]
    }
  }
  let data = $mcphost_common_config | upsert mcpServers ($mcphost_common_config.mcpServers | append $mcp_ssh_server)
  let config_path = (mktemp --suffix .yaml)
  $data | to yaml | save -f $config_path
  mcphost --config $config_path
}

def mcp-k8s [path:directory] {
  let mcp_server = {
    "k8s": {
      "command": "direnv",
      "args": [
        "exec",
        $path,
        "npx",
        "-y",
        "kubernetes-mcp-server@latest"
      ]
    }
  }
  let data = $mcphost_common_config | upsert mcpServers ($mcphost_common_config.mcpServers | append $mcp_server)
  let config_path = (mktemp --suffix .yaml -t)
  $data | to yaml | save -f $config_path
  mcphost --config $config_path
}

