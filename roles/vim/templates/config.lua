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

if IsModuleAvailable("lualine") then
    local function showFilePath()
      local filePath = vim.api.nvim_eval("expand('%')")
      return filePath
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
          lualine_c = {'hostname', 'getcwd', showFilePath},
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
            separator_style = {"📖|", "|"},
        }
    }
    vim.api.nvim_command([[
nnoremap <silent> H :BufferLineCyclePrev<CR>
nnoremap <silent> L :BufferLineCycleNext<CR>
inoremap <A-i> <Esc>:BufferLinePick<cr>
nnoremap <A-i> :BufferLinePick<cr>
tnoremap <A-i> <C-\><C-n>:BufferLinePick<cr>
nnoremap <silent> <leader>sb :BufferLineSortByDirectory<cr>
    ]])
end

if IsModuleAvailable("hop") then
  vim.api.nvim_set_keymap('n', 's', "<cmd>lua require'hop'.hint_words()<cr>", {})
end

if IsModuleAvailable("which-key") then
  local wk = require("which-key")
  wk.register({
    g = {
      name = "+Git",
    },
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
      name = "+Wiki/Window"
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
    },
    n = {
      name = "+Note",
    },
    i = {
      name = "+Insert time",
    },
    a = {
      name = "+AnyJump/CocAction",
    },
 
  }, { prefix = "<leader>" })

  require("which-key").setup {
    plugins = {
      registers = true
    }
  }

end
