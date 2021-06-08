local cmd = vim.cmd  -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn    -- to call Vim functions e.g. fn.bufnr()
local g = vim.g      -- a table to access global variables
local api = vim.api

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

if IsModuleAvailable("nvim-treesitter") then
    require "nvim-treesitter.configs".setup {
        ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
        highlight = {
            enable = true, -- false will disable the whole extension
            disable = { } -- list of language that will be disabled
        },
        rainbow = {
          enable = true,
          extended_mode = true, -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
          max_file_lines = 1000, -- Do not enable for files with more than 1000 lines, int
        }
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
            -- The first three options are required by nvim-dap
            type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
            request = "launch",
            name = "Launch file",
            -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

            program = "${file}", -- This configuration will launch the current file if used.
            pythonPath = function()
                -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
                -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
                -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
                local cwd = vim.fn.getcwd()
                if vim.fn.executable(cwd .. "/venv/bin/python") then
                    return "/usr/bin/python3"
                elseif vim.fn.executable(cwd .. "/.venv/bin/python") then
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
      local filePath = vim.api.nvim_eval("expand('%')")
      return filePath
    end
    local function showCWD()
      local path = vim.api.nvim_eval("getcwd()")
      local home = vim.api.nvim_eval("$HOME")
      path = path:gsub(home, '~')
      return path
    end
    require('lualine').setup{
        options = {
          theme = 'gruvbox_material',
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
        }
    }
end


if IsModuleAvailable("hlslens") then
    vim.api.nvim_command("noremap <silent> n <Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>")
    vim.api.nvim_command("noremap <silent> N <Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>")
    vim.api.nvim_command("noremap * *<Cmd>lua require('hlslens').start()<CR>")
    vim.api.nvim_command("noremap # #<Cmd>lua require('hlslens').start()<CR>")
    vim.api.nvim_command("noremap g* g*<Cmd>lua require('hlslens').start()<CR>")
    vim.api.nvim_command("noremap g# g#<Cmd>lua require('hlslens').start()<CR>")
end


if IsModuleAvailable("nvim-autopairs") then
    require('nvim-autopairs').setup()
    vim.api.nvim_command([[
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
            offsets = {{filetype = "NvimTree", text = "File Explorer", text_align = "center"}},
        }
    }
    vim.api.nvim_command([[
inoremap <A-i> <Esc>:BufferLinePick<cr>
nnoremap <A-i> :BufferLinePick<cr>
tnoremap <A-i> <C-\><C-n>:BufferLinePick<cr>
nnoremap <silent> <leader>sb :BufferLineSortByDirectory<cr>
nnoremap <silent> <C-h> :BufferLineMovePrev<CR>
nnoremap <silent> <C-l> :BufferLineMoveNext<CR>
nnoremap <silent> , :BufferLineCyclePrev<CR>
nnoremap <silent> . :BufferLineCycleNext<CR>
nnoremap <expr> <silent> , &filetype=='floaterm' ? ":call TermToggle()<cr>" : ":BufferLineCyclePrev<cr>"
nnoremap <expr> <silent> . &filetype=='floaterm' ? ":call TermToggle()<cr>" : ":BufferLineCycleNext<cr>"
    ]])
end

if IsModuleAvailable("hop") then
  vim.api.nvim_set_keymap('n', 's', "<cmd>lua require'hop'.hint_words()<cr>", {})
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
      vim.api.nvim_command(cmds)
      vim.api.nvim_set_var("MyRunLastCommand", cmds)
  elseif cmds == nil then
    cmds = vim.api.nvim_get_var("MyRunLastCommand")
    if cmds ~= nil then
      MyRun(cmds)
    end
  else
    vim.api.nvim_set_var("MyRunLastCommand", cmds)
    for k,v in pairs(cmds) do
      vim.api.nvim_command(v)
    end
  end
end
