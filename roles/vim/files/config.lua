local cmd = vim.cmd -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn -- to call Vim functions e.g. fn.bufnr()
local g = vim.g -- a table to access global variables
local api = vim.api

vim.diagnostic.config({
  virtual_text = {
    severity = vim.diagnostic.severity.ERROR,
    source = true,
  },
  float = {
    source = true,
  },
  update_in_insert = true
})

function Dump(o)
  print(vim.inspect(o))
end

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
    for _, searcher in ipairs(package.loaders) do
      local loader = searcher(name)
      if type(loader) == "function" then
        package.preload[name] = loader
        return true
      end
    end
    return false
  end
end

function SafeRequire(name)
  if IsModuleAvailable(name) then
    return require(name)
  end
  return {
    setup = function(arg)
    end
  }
end

function SafeRequireCallback(name, func)
  if IsModuleAvailable(name) then
    return func(require(name))
  end
end

SafeRequire "nvim-treesitter.configs".setup {
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
  },
  yati = {
    enable = true,
  }
}
SafeRequire 'nvim-treesitter.configs'.setup {
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
SafeRequire 'nvim-treesitter.configs'.setup {
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
SafeRequire 'nvim-treesitter.configs'.setup {
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

SafeRequire "nvim-treesitter.configs".setup {
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

SafeRequire 'nvim-treesitter.configs'.setup {
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

SafeRequireCallback('lualine', function(lualine)
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

  local floaterm_lualine = {
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
    filetypes = { 'floaterm' }
  }

  local tree_lualine = {
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'hostname' },
    },
    inactive_sections = {
      lualine_a = { 'hostname' },
    },
    filetypes = { 'nvim-tree', 'neo-tree', 'aerial', 'Trouble' }
  }

  lualine.setup {
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
    extensions = { floaterm_lualine, tree_lualine },
  }
end)


SafeRequireCallback("hlslens", function(hlslens)
  api.nvim_command("noremap <silent> n <Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>")
  api.nvim_command("noremap <silent> N <Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>")
  api.nvim_command("noremap * *<Cmd>lua require('hlslens').start()<CR>")
  api.nvim_command("noremap # #<Cmd>lua require('hlslens').start()<CR>")
  api.nvim_command("noremap g* g*<Cmd>lua require('hlslens').start()<CR>")
  api.nvim_command("noremap g# g#<Cmd>lua require('hlslens').start()<CR>")
end)

SafeRequireCallback("bufferline", function(bufferline)
  bufferline.setup {
    options = {
      diagnostics = "nvim_lsp",
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
        { filetype = "nerdtree", text = "File Explorer", text_align = "center" },
        { filetype = "neo-tree", text = "File Explorer", text_align = "center" },
      },
    }
  }
  api.nvim_command([[
nnoremap <silent> <leader>sb :BufferLineSortByDirectory<cr>
nnoremap <silent> <C-h> :BufferLineMovePrev<CR>
nnoremap <silent> <C-l> :BufferLineMoveNext<CR>
    ]])
end)

SafeRequireCallback("which-key", function(wk)
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

  wk.setup {
    plugins = {
      registers = true
    }
  }
end)

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

SafeRequire("persistence").setup {
}

SafeRequire('detect-language').setup {}

SafeRequire 'nvim-tree'.setup {
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

SafeRequire("nvim-lsp-installer").setup {
  automatic_installation = true,
}

SafeRequire 'marks'.setup {
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

SafeRequireCallback("cmp", function()
  local cmp = require 'cmp'
  local lspkind = require('lspkind')

  local source_mapping = {
    buffer = "[Buffer] 📦",
    nvim_lua = "[Lua] 🐖",
    cmp_tabnine = "[TN] 📝",
    path = "[Path] 📁",
    copilot = "[Copilot] ",
    fish = "[fish] 🐠",
    rg = "[rg] 🔎",
    luasnip = "[luasnip] 🐍",
  }

  local function custom_format(entry, vim_item)
    vim_item.kind = lspkind.presets.default[vim_item.kind]
    vim_item.abbr = all_trim(string.sub(vim_item.abbr, 1, 60))
    local source_name = entry.source.name
    if (vim_item.menu ~= nil and
        entry.completion_item.data ~= nil and
        entry.completion_item.data.detail ~= nil) then
      vim_item.menu = entry.completion_item.data.detail .. ' ' .. vim_item.menu
    end
    if source_mapping[source_name] then
      vim_item.kind = source_mapping[source_name]
    end
    return vim_item
  end

  local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
  end
  local luasnip = require("luasnip")
  require("luasnip.loaders.from_vscode").lazy_load()
  require("luasnip.loaders.from_vscode").lazy_load({ paths = '~/.config/nvim/plugged/friendly-snippets/' })

  if IsModuleAvailable("lsp_signature") then
    require "lsp_signature".setup({ floating_window = true, floating_window_off_y = -10,
      transparency = 50, max_height = 9, handler_opts = { border = "none" } })
  end

  if (cmp == nil) then
    return
  end
  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        require('luasnip').lsp_expand(args.body)
      end,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-g>'] = cmp.mapping(
        function(fallback)
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end,
        { "i", "s", --[[ "c" (to enable the mapping in command mode) ]] }
      ),
      ['<C-f>'] = cmp.mapping(
        function(fallback)
          if luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end,
        { "i", "s", --[[ "c" (to enable the mapping in command mode) ]] }
      ),
      ['<m-/>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'path' },
      { name = 'luasnip' }, -- For luasnip users.
      { name = 'copilot' },
      { name = 'cmp_tabnine' },
      { name = 'rg', max_item_count = 10 },
      { name = 'fish' },
      { name = 'buffer' },
    }),
    formatting = {
      format = custom_format,
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

  local search_sources = {
    { name = 'nvim_lsp_document_symbol' },
    { name = 'buffer' },
  }
  local function setup_cmdline(cmd_type, sources)
    cmp.setup.cmdline(cmd_type, {
      formatting = {
        format = custom_format,
      },
      mapping = cmp.mapping.preset.cmdline({
        ['<C-p>'] = {
          c = function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end,
        },
        ['<C-n>'] = {
          c = function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end,
        },
        ['<CR>'] = function(fallback)
          fallback()
        end
      }),
      view = {
        entries = { name = 'custom', selection_order = 'near_cursor' }
      },
      sources = sources
    })
  end

  setup_cmdline(':', {
    { name = 'path', group_index = 1 },
    { name = 'cmdline', group_index = 1},
    { name = 'cmdline_history' , group_index = 2},
  })
  setup_cmdline('/', search_sources)
  setup_cmdline('?', search_sources)

  -- Setup lspconfig.
  local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true
  }

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
end)

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

function FindFileCwd()
  local cwd = vim.fn.getcwd()
  local currentFile = vim.fn.expand('%:p')
  local gitDir = cwd .. '/.git'
  if currentFile ~= '' and string.find(currentFile, cwd) == nil then
    vim.cmd('Files')
  elseif vim.fn.isdirectory(gitDir) ~= 0 then
    vim.cmd('GitFiles')
  else
    vim.cmd('Files')
  end
end

vim.api.nvim_set_keymap('n', '<c-p>', '', { silent = true, callback = FindFileCwd, desc = 'Find file' })

function FindFileBuffer()
  local oldCwd = vim.fn.getcwd()
  local currentBufferPath = vim.fn.expand('%:p:h')
  vim.cmd('cd ' .. currentBufferPath)
  vim.cmd('Files')
  vim.cmd('cd ' .. oldCwd)
end

vim.api.nvim_set_keymap('', '<leader>zf', '', { silent = true, callback = FindFileBuffer, desc = 'Find file in buffer' })

function TermToggle()
  local bufList = vim.api.nvim_eval("map(filter(range(0, bufnr('$')), 'bufwinnr(v:val)>=0'), 'bufname(v:val)')")
  for i in pairs(bufList) do
    if string.find(bufList[i], 'term://') then
      vim.cmd("FloatermHide!")
      return
    end
  end
  vim.cmd("FloatermToggle")
end

function DelaySetup2()
  SafeRequireCallback("dap", function(dap)
    dap.adapters.dart = {
      type = "executable",
      command = "dart",
      args = { "debug_adapter" }
    }
    dap.configurations.dart = {
      {
        type = "dart",
        request = "launch",
        name = "Launch Dart Program",
        program = "${file}",
        cwd = "${workspaceFolder}",
      }
    }
  end)
  SafeRequire('dap-python').setup(vim.api.nvim_eval("g:python3_host_prog"))
  SafeRequire("trouble").setup {}
  SafeRequire("dapui").setup {}
  SafeRequire('aerial').setup()
  SafeRequire('neogen').setup {}
  SafeRequire('rest-nvim').setup {
    jump_to_request = true,
    env_file = '.env',
    skip_ssl_verification = true
  }
  SafeRequireCallback("hop", function(hop)
    api.nvim_set_keymap('n', 's', "<cmd>lua require'hop'.hint_words()<cr>", {})
    hop.setup {
      winblend = 10,
      jump_on_sole_occurrence = true,
      create_hl_autocmd = true,
      reverse_distribution = false
    }
  end)
  SafeRequireCallback("nvim-autopairs", function(autopairs)
    autopairs.setup()
    api.nvim_command([[
  nmap <C-a> <Plug>(dial-increment)
  nmap <C-x> <Plug>(dial-decrement)
  vmap <C-a> <Plug>(dial-increment)
  vmap <C-x> <Plug>(dial-decrement)
  vmap g<C-a> <Plug>(dial-increment-additional)
  vmap g<C-x> <Plug>(dial-decrement-additional)
      ]])
  end)

end

function DelaySetup1()
  SafeRequire('neo-tree').setup({
    window = {
      width = 30,
      max_width = 30,
    },
  })
  SafeRequireCallback('lspsaga', function(saga)
    saga.init_lsp_saga()
  end)
  SafeRequire('fzf_lsp').setup()
  SafeRequireCallback("ufo", function(ufo)
    vim.wo.foldcolumn = '1'
    vim.wo.foldlevel = 99
    vim.wo.foldenable = true
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true
    }
    ufo.setup()
  end)
  SafeRequire("cybu").setup()
  SafeRequire("fidget").setup()
  SafeRequire("nvim-gps").setup {}
  SafeRequire("scrollbar").setup()
  SafeRequire("focus").setup({
    signcolumn = false,
  })
  vim.schedule(DelaySetup2)

end

vim.schedule(DelaySetup1)

function GetBuffers()
  local buffers = {}
  local len = 0
  local vim_fn = vim.fn
  local buflisted = vim_fn.buflisted

  for buffer = 1, vim_fn.bufnr('$') do
    len = len + 1
    buffers[len] = vim.fn.bufname(buffer)
  end
  return buffers
end

function HasTerminal()
  local bufList = GetBuffers()
  for key, name in pairs(bufList) do
    if string.find(name, 'term://') then
      return true
    end
  end
  return false
end

function RunPreviousCommandFunc()
  if HasTerminal() == false then
    vim.cmd("FloatermNew")
  end
  local mode = vim.fn.mode()
  if mode == 't' then
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<c-p>", true, true, true), 't')
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<cr>", true, true, true), 't')
  elseif mode == 'n' then
    vim.cmd("FloatermShow")
    vim.fn.feedkeys('i', 't')
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<c-p>", true, true, true), 't')
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<cr>", true, true, true), 't')
  elseif mode == 'i' then
    vim.cmd("stopinsert")
    vim.cmd("FloatermShow")
    vim.fn.feedkeys('i', 't')
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<c-p>", true, true, true), 't')
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<cr>", true, true, true), 't')
  end
end

function LspFormat()
  local api_level = vim.version().api_level
  if api_level == 9 then
    vim.lsp.buf.formatting()
  elseif api_level >= 10 then
    vim.lsp.buf.format { async = true }
  end
end

function RunShellAndShow(command)
  if HasTerminal() == false then
    vim.cmd("FloatermNew")
  end
  vim.cmd("FloatermShow")
  vim.cmd("FloatermSend " .. command .. "")
end
