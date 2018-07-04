" EverVim Configuration Root Directory
if empty($evervim_root)
    let $evervim_root = "~/EverVim"
endif

" Evervim use `,` for leader.
" To open leader guide, use `<space>`
" You need to unmap `<space>` from `keybindings.vim`.

" Core Config
source $evervim_root/core/core.vim
set timeoutlen=500
set noswapfile
set nofoldenable
if executable("fish") == 1
  set shell=fish
endif
let g:ale_open_list = 0
let g:pymode_lint_ignore = ["E501", "W",]
tunmap <Esc>

" All of them, for testing purpose
let g:evervim_bundle_groups=[
            \ 'general',
            \ 'appearance',
            \ 'writing',
            \ 'youcompleteme',
            \ 'programming',
            \ 'misc',
            \ 'python',
            \ 'javascript',
            \ 'typescript',
            \ 'html',
            \ 'css',
            \ 'go',
            \ ]

{% include './templates/keybindings.vim' %}
