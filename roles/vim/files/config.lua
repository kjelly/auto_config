local cmd = vim.cmd  -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn    -- to call Vim functions e.g. fn.bufnr()
local g = vim.g      -- a table to access global variables
local api = vim.api

local function indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
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
          require'bufferline'.sort_buffers_by(MySort)
          return 1000
      end
  )
end

if IsModuleAvailable("nvim-treesitter") then
    require "nvim-treesitter.configs".setup {
        ensure_installed = "maintained",
        refactor = {
          highlight_definitions = { enable = true },
          highlight_current_scope = { enable = false},
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
            disable = { }
        },
        rainbow = {
          enable = true,
          extended_mode = true,
          max_file_lines = 1000,
        }
    }
    require'nvim-treesitter.configs'.setup {
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
    require'nvim-treesitter.configs'.setup {
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
    require'nvim-treesitter.configs'.setup {
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

    require'treesitter-context.config'.setup{
      enable = false,
      throttle = false,
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

    require'nvim-treesitter.configs'.setup {
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
        args = {"-m", "debugpy.adapter"}
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

    local my_extension = {
      sections = {
        lualine_a = {'mode'},
        lualine_b = {},
        lualine_c = {floatermInfo, termTitle},
        lualine_y = {},
        lualine_z = {'progress'},
      },
      inactive_sections = {
        lualine_c = {floatermInfo},
        lualine_z = {'location'},
      },
      filetypes = {'floaterm'}}

    require('lualine').setup{
        options = {
          theme = 'auto',
          section_separators = {'', ''},
          component_separators = {'', ''},
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff'},
          lualine_c = {'hostname', showCWD, showFilePath},
          lualine_x = {'encoding', 'fileformat', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {showFilePath},
          lualine_x = {'location'},
          lualine_y = {},
          lualine_z = {}
        },
        extensions = {my_extension},
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
    require'bufferline'.setup{
        options={
            diagnostics = "coc",
            diagnostics_indicator = function(count, level, diagnostics_dict, context)
              local s = " "
              for e, n in pairs(diagnostics_dict) do
                local sym = e == "error" and " "
                  or (e == "warning" and " " or "" )
                s = s .. n .. sym
              end
              return s
            end,
            view = "multiwindow" ,
            always_show_bufferline = true,
            buffer_close_icon= '❌',
            modified_icon = '●',
            close_icon = '❌',
            show_close_icon = false,
            show_buffer_close_icons = false,
            left_trunc_marker = '◀',
            right_trunc_marker = '▶',
            indicator_icon = '📌',
            separator_style = {"📌|", "|"},
            offsets = {{filetype = "NvimTree", text = "File Explorer", text_align = "center"},
                       {filetype = "nerdtree", text = "File Explorer", text_align = "center"}
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
  require'hop'.setup {
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
        "ddgr"
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
      name = "+Move",
      p = { 'Previous mark'},
      n = { 'Next mark'},
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
        l = { "git diff last commit"}
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
    for k,v in pairs(cmds) do
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
  require'nvim-tree'.setup {
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
      auto_resize = true,
    }
  }
end

if IsModuleAvailable("lspconfig") then
  require'lspconfig'.pyright.setup{}
end
if IsModuleAvailable("marks") then
  require'marks'.setup {
    default_mappings = true,
    builtin_marks = { ".", "<", ">", "^" },
    cyclic = true,
    force_write_shada = false,
    refresh_interval = 250,
    sign_priority = { lower=10, upper=15, builtin=8, bookmark=20 },
    bookmark_0 = {
      sign = "⚑",
      virt_text = "hello world"
    },
    mappings = {}
  }
end
