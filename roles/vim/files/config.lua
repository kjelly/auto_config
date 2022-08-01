local cmd = vim.cmd -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn -- to call Vim functions e.g. fn.bufnr()
local g = vim.g -- a table to access global variables
local api = vim.api


function FileExists(name)
  local f = io.open(name, "r")
  if f ~= nil then io.close(f) return true else return false end
end

LSP_CONFIG = {
  sumneko_lua = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { 'vim' },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
    },
  },
  pyright = {
    python = {
      venvPath = vim.fn.expand("$HOME/.cache/pypoetry/virtualenvs/"),
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true
      }
    }
  },
  pylsp = {
    plugin = {
      pylint = {
        enabled = true
      }
    }
  }
}

-- show caps
-- :lua =vim.lsp.get_active_clients()[1].server_capabilities
local disabled_lsp_caps = {
  pylsp = { 'renameProvider', 'referencesProvider', 'hoverProvider' },
  jedi_language_server = { 'renameProvider', 'referencesProvider', 'hoverProvider' },
}

local langservers = {
  'ansiblels', 'bashls', 'cssls', 'dartls', 'dockerls', 'emmet_ls', 'gopls', 'graphql', 'html',
  'jsonls', 'marksman', 'pylsp', 'pyright', 'rust_analyzer', 'sqlls', 'sqls', 'sumneko_lua', 'terraformls', 'tsserver',
  'vimls', 'yamlls'
}

local function smart_dd()
  if vim.api.nvim_get_current_line():match("^%s*$") then
    return "\"_dd"
  else
    return "dd"
  end
end

vim.keymap.set("n", "dd", smart_dd, { noremap = true, expr = true })

local function indexOf(array, value)
  for i, v in ipairs(array) do
    if v == value then
      return i
    end
  end
  return nil
end

local function all_trim(s)
  return s:match("^%s*(.-)%s*$")
end

function IsModuleAvailable(name)
  if package.loaded[name] then
    return true
  else
    for _, searcher in ipairs(package.searchers or package.loaders) do
      local loader = searcher(name)
      if type(loader) == "function" then
        package.preload[name] = loader
        return true
      end
    end
    return false
  end
end

if IsModuleAvailable("timer") then
  require "timer".add(
    function()
      return 1000
    end
  )
end

if IsModuleAvailable("nvim-treesitter") then
  require "nvim-treesitter.configs".setup {
    ensure_installed = "all",
    refactor = {
      highlight_definitions = { enable = true },
      highlight_current_scope = { enable = false },
      smart_rename = {
        enable = true,
        keymaps = {
          smart_rename = "grr",
        },
      },
    },
    autopairs = {
      enable = true,
    },
    iswap = {
      enable = true,
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "+",
        node_incremental = "+",
        scope_incremental = "grc",
        node_decremental = "_",
      },
    },
    indent = {
      enable = false,
    },
    highlight = {
      enable = true,
      disable = {}
    },
    rainbow = {
      enable = true,
      extended_mode = true,
      max_file_lines = 1000,
    }
  }
  require 'nvim-treesitter.configs'.setup {
    textobjects = {
      select = {
        enable = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["ao"] = "@block.outer",
          ["io"] = "@block.inner",
          ["aCa"] = "@call.outer",
          ["iCa"] = "@call.inner",
          ["aCo"] = "@conditional.outer",
          ["iCo"] = "@conditional.inner",
          ["aCm"] = "@comment.outer",
          ["aF"] = "@frame.outer",
          ["iF"] = "@frame.inner",
          ["al"] = "@loop.outer",
          ["il"] = "@loop.inner",
          ["ap"] = "@parameter.outer",
          ["ip"] = "@parameter.inner",
          ["as"] = "@statement.outer",
          ["is"] = "@scopename.inner",
        },
      },
    },
  }
  require 'nvim-treesitter.configs'.setup {
    textobjects = {
      swap = {
        enable = true,
        swap_next = {
          ["<leader>lsa"] = "@parameter.inner",
        },
        swap_previous = {
          ["<leader>lsA"] = "@parameter.inner",
        },
      },
    },
  }
  require 'nvim-treesitter.configs'.setup {
    textobjects = {
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]]"] = "@class.outer",
        },
        goto_next_end = {
          ["]M"] = "@function.outer",
          ["]["] = "@class.outer",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[["] = "@class.outer",
        },
        goto_previous_end = {
          ["[M"] = "@function.outer",
          ["[]"] = "@class.outer",
        },
      },
    },
  }

  require "nvim-treesitter.configs".setup {
    playground = {
      enable = true,
      disable = {},
      updatetime = 25,
      persist_queries = false,
      keybindings = {
        toggle_query_editor = 'o',
        toggle_hl_groups = 'i',
        toggle_injected_languages = 't',
        toggle_anonymous_nodes = 'a',
        toggle_language_display = 'I',
        focus_language = 'f',
        unfocus_language = 'F',
        update = 'R',
        goto_node = '<cr>',
        show_help = '?',
      },
    }
  }

  require 'nvim-treesitter.configs'.setup {
    refactor = {
      navigation = {
        enable = true,
        keymaps = {
          goto_definition = "gnd",
          list_definitions = "gnD",
          list_definitions_toc = "gO",
          goto_next_usage = "gnu",
          goto_previous_usage = "gnU",
        },
      },
    },
  }
end

if IsModuleAvailable("dap") then
  local dap = require("dap")
  dap.adapters.python = {
    type = "executable",
    command = "/usr/bin/python3",
    args = { "-m", "debugpy.adapter" }
  }

  dap.configurations.python = {
    {
      type = "python",
      request = "launch",
      name = "Launch file",

      program = "${file}",
      pythonPath = function()
        local cwd = fn.getcwd()
        if fn.executable(cwd .. "/venv/bin/python") then
          return "/usr/bin/python3"
        elseif fn.executable(cwd .. "/.venv/bin/python") then
          return "/usr/bin/python3"
        else
          return "/usr/bin/python3"
        end
      end
    }
  }
end

if IsModuleAvailable("zero") then
  require('zero').setup()
end

if IsModuleAvailable("lualine") then
  local function showFilePath()
    local filePath = api.nvim_eval("expand('%')")
    return filePath
  end

  local function showCWD()
    local path = api.nvim_eval("getcwd()")
    local home = api.nvim_eval("$HOME")
    path = path:gsub(home, '~')
    return path
  end

  local function floatermInfo()
    local bufid = api.nvim_get_current_buf()
    local buffers = api.nvim_eval("floaterm#buflist#gather()")
    local title = api.nvim_buf_get_var(bufid, 'term_title')
    local ret = indexOf(buffers, bufid) .. '/' .. #buffers
    return ret
  end

  local function termTitle()
    local title = api.nvim_buf_get_var(nil, 'term_title')
    return title
  end

  local function gpsLocation()
    if IsModuleAvailable("nvim-gps") then
      local gps = require("nvim-gps")
      return gps.get_location()
    end
    return ''
  end

  local my_extension = {
    sections = {
      lualine_a = { 'mode' },
      lualine_b = {},
      lualine_c = { floatermInfo, termTitle },
      lualine_y = {},
      lualine_z = { 'progress' },
    },
    inactive_sections = {
      lualine_c = { floatermInfo },
      lualine_z = { 'location' },
    },
    filetypes = { 'floaterm' } }

  require('lualine').setup {
    options = {
      theme = 'auto',
      section_separators = { '', '' },
      component_separators = { '', '' },
    },
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch', 'diff' },
      lualine_c = { 'hostname', showCWD, showFilePath },
      lualine_x = { gpsLocation, 'encoding', 'fileformat', 'filetype' },
      lualine_y = { 'progress' },
      lualine_z = { 'location' }
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { showFilePath },
      lualine_x = { 'location' },
      lualine_y = {},
      lualine_z = {}
    },
    extensions = { my_extension },
  }
end


if IsModuleAvailable("hlslens") then
  api.nvim_command("noremap <silent> n <Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>")
  api.nvim_command("noremap <silent> N <Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>")
  api.nvim_command("noremap * *<Cmd>lua require('hlslens').start()<CR>")
  api.nvim_command("noremap # #<Cmd>lua require('hlslens').start()<CR>")
  api.nvim_command("noremap g* g*<Cmd>lua require('hlslens').start()<CR>")
  api.nvim_command("noremap g# g#<Cmd>lua require('hlslens').start()<CR>")
end


if IsModuleAvailable("nvim-autopairs") then
  require('nvim-autopairs').setup()
  api.nvim_command([[
nmap <C-a> <Plug>(dial-increment)
nmap <C-x> <Plug>(dial-decrement)
vmap <C-a> <Plug>(dial-increment)
vmap <C-x> <Plug>(dial-decrement)
vmap g<C-a> <Plug>(dial-increment-additional)
vmap g<C-x> <Plug>(dial-decrement-additional)
    ]])
end

if IsModuleAvailable("bufferline") then
  require 'bufferline'.setup {
    options = {
      diagnostics = "coc",
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        local s = " "
        for e, n in pairs(diagnostics_dict) do
          local sym = e == "error" and " "
              or (e == "warning" and " " or "")
          s = s .. n .. sym
        end
        return s
      end,
      view = "multiwindow",
      always_show_bufferline = true,
      buffer_close_icon = '❌',
      modified_icon = '●',
      close_icon = '❌',
      show_close_icon = false,
      show_buffer_close_icons = false,
      left_trunc_marker = '◀',
      right_trunc_marker = '▶',
      indicator_icon = '📌',
      separator_style = { "📌|", "|" },
      offsets = { { filetype = "NvimTree", text = "File Explorer", text_align = "center" },
        { filetype = "nerdtree", text = "File Explorer", text_align = "center" }
      },
    }
  }
  api.nvim_command([[
nnoremap <silent> <leader>sb :BufferLineSortByDirectory<cr>
nnoremap <silent> <C-h> :BufferLineMovePrev<CR>
nnoremap <silent> <C-l> :BufferLineMoveNext<CR>
    ]])
end

if IsModuleAvailable("hop") then
  api.nvim_set_keymap('n', 's', "<cmd>lua require'hop'.hint_words()<cr>", {})
  require 'hop'.setup {
    winblend = 10,
    jump_on_sole_occurrence = true,
    create_hl_autocmd = true,
    reverse_distribution = false
  }
end

if IsModuleAvailable("which-key") then
  local wk = require("which-key")
  wk.register({
    g = {
      r = {
        name = 'rename',
        r = 'rename'
      },
      n = {
        name = 'navigation',
        d = 'goto_definition',
        D = 'list_definitions',
        u = 'goto_next_usage',
        U = 'goto_previous_usage',
      },
      O = 'list_definitions_toc',
    },
    d = {
      i = {
        o = 'block',
        f = 'function',
        c = 'class',
        C = {
          name = 'Call/Comment/Conditional',
          a = 'call',
          o = 'conditional',
          m = 'comment',
        },
        F = 'frame',
        l = 'loop',
        p = 'parameter',
        s = 'scopename',
      },
      a = {
        o = 'block',
        f = 'function',
        c = 'class',
        C = {
          name = 'Call/Comment/Conditional',
          a = 'call',
          o = 'conditional',
          m = 'comment',
        },
        F = 'frame',
        l = 'loop',
        p = 'parameter',
        s = 'scopename',
      }
    }
  })
  wk.register({
    r = {
      name = "+Run"
    },
    d = {
      name = "+Debug"
    },
  }, { prefix = "<localleader>" })
  wk.register({
    z = {
      name = "+Grep/Find/FZF"
    },
    t = {
      name = "+Tab"
    },
    b = {
      name = "+Buffer/Bookmark",
      c = {
        "Copy file path"
      }
    },
    c = {
      name = "+Comment/cd"
    },
    q = {
      name = "+Quit"
    },
    l = {
      name = "+Language",
      d = {
        "declaration/definition"
      },
      e = {
        "Leetcode",
      },
      s = {
        "Doc/Workspace Symbol",
      },
      r = {
        "Rename/Reference",
      },
      t = {
        "Test",
      },
    },
    f = {
      name = "+File/esearch"
    },
    s = {
      name = "+Status"
    },
    m = {
      name = "+Mark",
      p = { 'Previous mark' },
      n = { 'Next mark' },
    },
    w = {
      name = "+Wiki/Window",
      q = { "wqa" },
      s = { "split" }
    },
    r = {
      name = "+Run/Test"
    },
    o = {
      name = "+Fold"
    },
    e = {
      name = "+Edit"
    },
    g = {
      name = "+Git/Paste",
      d = {
        name = "git diff",
        l = { "git diff last commit" }
      }
    },
    n = {
      name = "+Note",
    },
    i = {
      name = "+Insert time/Info",
    },
    a = {
      name = "+AnyJump/CocAction",
    },
    v = {
      name = "+Gina"

    },
    p = {
      name = "+Paste/Plugin"
    },
  }, { prefix = "<leader>" })

  require("which-key").setup {
    plugins = {
      registers = true
    }
  }
end

function MyRun(cmds)
  if type(cmds) == "string" then
    api.nvim_command(cmds)
    api.nvim_set_var("MyRunLastCommand", cmds)
  elseif cmds == nil then
    cmds = api.nvim_get_var("MyRunLastCommand")
    if cmds ~= nil then
      MyRun(cmds)
    end
  else
    api.nvim_set_var("MyRunLastCommand", cmds)
    for _, v in pairs(cmds) do
      api.nvim_command(v)
    end
  end
end

function MySort(buffer_a, buffer_b)
  local function _sort()
    local a_atime = api.nvim_buf_get_var(buffer_a.id, 'atime')
    local b_atime = api.nvim_buf_get_var(buffer_b.id, 'atime')
    if a_atime > b_atime then
      return true
    elseif a_atime < b_atime then
      return false
    end
    return buffer_a.id > buffer_b.id
  end

  local status, retval = pcall(_sort)
  if status then
    return retval
  else
    return buffer_a.id > buffer_b.id
  end
end

if IsModuleAvailable("persistence") then
  require("persistence").setup {
  }
end

if IsModuleAvailable("detect-language") then
  require('detect-language').setup {}
end

if IsModuleAvailable("nvim-tree") then
  require 'nvim-tree'.setup {
    diagnostics = {
      enable = true,
      icons = {
        hint = "",
        info = "",
        warning = "",
        error = "",
      }
    },
    update_focused_file = {
      enable      = true,
      update_cwd  = false,
      ignore_list = {}
    },
    filters = {
      dotfiles = false,
      custom = {}
    },
    system_open = {
      cmd  = 'file',
      args = {}
    },
    view = {
      width = '18%',
      side = 'left',
      mappings = {
        custom_only = true,
        list = {
          { key = { "<CR>", "o", "<2-LeftMouse>" }, action = "edit" },
          { key = "<C-e>", action = "edit_in_place" },
          { key = { "O" }, action = "edit_no_picker" },
          { key = { "<2-RightMouse>", "<C-]>" }, action = "cd" },
          { key = "<C-v>", action = "vsplit" },
          { key = "<C-x>", action = "split" },
          { key = "<C-t>", action = "tabnew" },
          { key = "<", action = "prev_sibling" },
          { key = ">", action = "next_sibling" },
          { key = "P", action = "parent_node" },
          { key = "<BS>", action = "close_node" },
          { key = "<Tab>", action = "preview" },
          { key = "K", action = "first_sibling" },
          { key = "J", action = "last_sibling" },
          { key = "I", action = "toggle_git_ignored" },
          { key = "H", action = "toggle_dotfiles" },
          { key = "R", action = "refresh" },
          { key = "a", action = "create" },
          { key = "d", action = "remove" },
          { key = "D", action = "trash" },
          { key = "r", action = "rename" },
          { key = "<C-r>", action = "full_rename" },
          { key = "x", action = "cut" },
          { key = "c", action = "copy" },
          { key = "p", action = "paste" },
          { key = "y", action = "copy_name" },
          { key = "Y", action = "copy_path" },
          { key = "gy", action = "copy_absolute_path" },
          { key = "[c", action = "prev_git_item" },
          { key = "]c", action = "next_git_item" },
          { key = "-", action = "dir_up" },
          { key = "q", action = "close" },
          { key = "g?", action = "toggle_help" },
          { key = "W", action = "collapse_all" },
          { key = "S", action = "search_node" },
          { key = "<C-k>", action = "toggle_file_info" },
          { key = ".", action = "run_file_command" }
        }
      }
    },
    actions = {
      open_file = {
        quit_on_open = false,
        resize_window = false,
        window_picker = {
          enable = true,
          chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
          exclude = {
            filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
            buftype = { "nofile", "terminal", "help" },
          },
        },
      },
    },
    renderer = {
      add_trailing = false,
      group_empty = false,
      highlight_git = false,
      full_name = false,
      highlight_opened_files = "none",
      root_folder_modifier = ":~",
      indent_markers = {
        enable = false,
        icons = {
          corner = "└ ",
          edge = "│ ",
          item = "│ ",
          none = "  ",
        },
      },
      icons = {
        webdev_colors = true,
        git_placement = "before",
        padding = " ",
        symlink_arrow = "",
        show = {
          file = true,
          folder = true,
          folder_arrow = true,
          git = true,
        },
        glyphs = {
          default = "",
          symlink = "",
          folder = {
            arrow_closed = "",
            arrow_open = "",
            default = "",
            open = "",
            empty = "",
            empty_open = "",
            symlink = "",
            symlink_open = "",
          },
          git = {
            unstaged = "❌",
            staged = "✅",
            unmerged = "",
            renamed = "㈴",
            untracked = "🚩",
            deleted = "",
            ignored = "◌",
          },
        },
      },
      special_files = { "Cargo.toml", "Makefile", "README.md", "readme.md" },
    },
  }
end

if IsModuleAvailable("lspconfig") then
  require("nvim-lsp-installer").setup {
    automatic_installation = true,
  }
end

if IsModuleAvailable("marks") then
  require 'marks'.setup {
    default_mappings = true,
    builtin_marks = { ".", "<", ">", "^" },
    cyclic = true,
    force_write_shada = false,
    refresh_interval = 250,
    sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
    bookmark_0 = {
      sign = "⚑",
      virt_text = "hello world"
    },
    mappings = {}
  }
end


if IsModuleAvailable("nvim-gps") then
  require("nvim-gps").setup {
  }
end


if IsModuleAvailable("scrollbar") then
  require("scrollbar").setup()
end

if IsModuleAvailable("focus") then
  require("focus").setup({
    signcolumn = false
  })
end

if IsModuleAvailable("neogen") then
  require('neogen').setup {}
end

if IsModuleAvailable("rest-nvim") then
  require('rest-nvim').setup {
    jump_to_request = true,
    env_file = '.env',
    skip_ssl_verification = true
  }
end


if IsModuleAvailable("cmp") then
  local cmp = require 'cmp'
  local lspkind = require('lspkind')

  local source_mapping = {
    buffer = "[Buffer]",
    nvim_lsp = "[LSP]",
    nvim_lua = "[Lua]",
    cmp_tabnine = "[TN]",
    path = "[Path]",
  }
  if(cmp == nil) then
    return
  end

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      end,
    },
    window = {
      -- completion = cmp.config.window.bordered(),
      -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'path' },
      { name = 'luasnip' }, -- For luasnip users.
      { name = 'copilot' },
      { name = 'cmp_tabnine' },
    }, {
      { name = 'buffer' },
    }),
    formatting = {
      format = function(entry, vim_item)
        vim_item.kind = lspkind.presets.default[vim_item.kind]
        vim_item.abbr = all_trim(string.sub(vim_item.abbr, 1, 60))
        local menu = source_mapping[entry.source.name]
        if entry.source.name == 'cmp_tabnine' then
          if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
            menu = entry.completion_item.data.detail .. ' ' .. menu
          end
          vim_item.kind = ''
        end
        if entry.source.name == "copilot" then
          vim_item.kind = "[] Copilot"
          vim_item.kind_hl_group = "CmpItemKindCopilot"
          return vim_item
        end
        vim_item.menu = menu
        return vim_item
      end
    },
  })

  -- Set configuration for specific filetype.
  cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
      { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
    }, {
      { name = 'buffer' },
    })
  })

  -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })

  -- Setup lspconfig.
  local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true
  }


  -- Mappings.
  -- See `:help vim.diagnostic.*` for documentation on any of the below functions
  local opts = { noremap = true, silent = true }
  vim.api.nvim_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
  vim.api.nvim_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  vim.api.nvim_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  vim.api.nvim_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)

  -- Use a loop to conveniently call 'setup' on multiple servers and
  -- map buffer local keybindings when the language server attaches
  for _, lsp in pairs(langservers) do
    local on_attach = function(client, bufnr)
      -- Enable completion triggered by <c-x><c-o>
      vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
      if disabled_lsp_caps[lsp] then
          for _, cap in ipairs(disabled_lsp_caps[lsp]) do
            client.server_capabilities[cap] = false
          end
      end
    end

    require('lspconfig')[lsp].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      flags = {
        -- This will be the default in neovim 0.7+
        debounce_text_changes = 150,
      },
      settings = LSP_CONFIG[lsp] or {},
    }
  end
  require 'fzf_lsp'.setup()
  require('aerial').setup({})

  local tabnine = require('cmp_tabnine.config')
  tabnine:setup({
    max_lines = 1000;
    max_num_results = 20;
    sort = true;
    run_on_every_keystroke = true;
    snippet_placeholder = '..';
    ignored_file_types = {
    };
    show_prediction_strength = false;
  })
end

if IsModuleAvailable("ufo") then
  vim.wo.foldcolumn = '1'
  vim.wo.foldlevel = 99
  vim.wo.foldenable = true
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true
  }
  require('ufo').setup()
end

if IsModuleAvailable("cybu") then
  require("cybu").setup()
end

if IsModuleAvailable("fidget") then
  require("fidget").setup()
end

local function getWorkspaceVimPath()
  local function convertName(name)
    local firstChar = string.sub(name, 1, 1)
    local lastChar = string.sub(name, #name, #name)
    local startPos = 1
    local endPos = #name
    if firstChar == '/' then
      startPos = 2
    end
    if lastChar == '/' then
      endPos = #name - 1
    end
    name = string.sub(name, startPos, endPos)
    name = string.gsub(name, "/", '-')
    return name
  end

  local workspace_path = vim.api.nvim_eval("g:MYVIMRC_DIR") .. '/workspaces/'
  os.execute('mkdir -p ' .. workspace_path)
  local workspaceConfigPath = workspace_path .. convertName(vim.fn.getcwd()) .. '.vim'
  return workspaceConfigPath
end

WorkspaceVimPath = getWorkspaceVimPath()

if FileExists(WorkspaceVimPath) then
  pcall(vim.api.nvim_command, 'source ' .. WorkspaceVimPath)
end

vim.api.nvim_set_keymap('n', '<Leader>esw', '', {
  noremap = true,
  desc = 'Edit workspace vim',
  callback = function()
    vim.api.nvim_command('edit ' .. WorkspaceVimPath)
    pcall(vim.api.nvim_command, 'edit ' .. WorkspaceVimPath)
  end,
})

if IsModuleAvailable('lspsaga') then
  local saga = require 'lspsaga'
  saga.init_lsp_saga({
  })
end

