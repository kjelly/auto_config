" Modeline and Notes {
"   EverVim is a modern & powerful vim distribution
"   Repo URL: https://github.com/LER0ever/EverVim
"   Made by [LER0ever](https://github.com/LER0ever)
"   Licensed under
"       * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE.md) or http://www.apache.org/licenses/LICENSE-2.0)
" }

" EverVim Configuration Root Directory
if empty($evervim_root)
    let $evervim_root = "~/.EverVim"
endif

" Core Config
source $evervim_root/core/core.vim
set timeoutlen=500
set noswapfile
tnoremap <Esc> <Esc>


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
