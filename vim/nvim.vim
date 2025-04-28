let mapleader = ","
let maplocalleader = "\<space>"

autocmd! BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

" Don't close window, when deleting a buffer
command! Bclose call <SID>BufcloseCloseIt()
command! SearchPanel :lua require('spectre').open()<CR>
command! Br :FloatermNew --autoclose=1 br<cr>
command! FormatJson :%!format_json.py

function! <SID>BufcloseCloseIt()
  let l:currentBufNum = bufnr("%")
  let l:alternateBufNum = bufnr("#")

  if buflisted(l:alternateBufNum)
    buffer #
  else
    bnext
  endif

  if bufnr("%") == l:currentBufNum
    new
  endif

  if buflisted(l:currentBufNum)
    execute("bdelete! ".l:currentBufNum)
  endif
endfunction

function! s:DiffWithSaved()
  let filetype=&ft
  diffthis
  vnew | r # | normal! 1Gdd
  diffthis
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype
endfunction

function! FindFileInTree()
  if exists(":Neotree")
    execute "Neotree reveal"
  elseif exists(":NvimTreeFindFile")
    execute "NvimTreeFindFile"
  elseif exists(":NERDTreeTabsFind")
    execute "NERDTreeMirrorOpen"
    execute "NERDTreeTabsFind"
  endif
endfunction

function! EditTodayNote() abort
  let path = "~/notes/journals/"
  let file_name = path.strftime("%Y-%m-%d.md")
  " Empty buffer
  if filereadable(expand(file_name))
    execute "e ".fnameescape(file_name)
  else
    call system("cp '~/notes/templates/daily template.md' ~/notes/journals/".fnameescape(file_name))
    execute "e ".fnameescape(file_name)
  endif
endfunction

set background=light
set splitkeep=screen
set title
set nu
set keywordprg=sdcvh.sh
set cursorline
set showcmd
set mouse=a

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

" Remember info about register, marks. And no highlight when started
set viminfo=<800,'10,h

" Show tab line if there are more than one tab
set showtabline=0

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Files, backups and undo
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set dir=~/.vim_cache/swapfiles
set backup
set backupdir=~/.vim_cache
set undodir=~/.vim_cache
set undofile

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => VIM user interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set 7 lines to the cursor - when moving vertically using j/k
set so=7

" Ignore compiled files
set wildignore=*.o,*~,*.pyc

" Height of the command bar
set cmdheight=1

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
" set whichwrap+=<,>

" When searching try to be smart about cases
set smartcase

" Don't redraw while executing macros (good performance config)
set nolazyredraw

" Show matching brackets when text indicator is over them
set showmatch
" How many tenths of a second to blink when matching brackets
set mat=2

set tm=500

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Text, tab and indent related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set expandtab
set smarttab

" 1 tab == 2 spaces
set shiftwidth=2
set tabstop=2

" Linebreak on 500 characters
set lbr
set tw=500

set si "Smart indent
set wrap "Wrap lines

" Always show the status line
set laststatus=3

" The time in milliseconds that is waited for
" a mapped sequence to complete.
set timeoutlen=500
set updatetime=300
set completeopt=menuone,noselect,fuzzy,popup
set listchars=tab:►\ ,trail:~,extends:>,precedes:<
set list
set sessionoptions=buffers,curdir,tabpages,winsize,globals
" suppress the annoying 'match x of y', 'The only match' and 'Pattern not
" found' messages
" or don't give |ins-completion-menu| messages.
set shortmess=sTWAIFS
" always show signcolumns
set signcolumn=yes
set noshowmode
set spell
set spelloptions=camel
set inccommand=split
set winblend=0
set pumblend=0

if executable('nu') == 1
  set shell=nu
elseif executable('fish') == 1
  set shell=fish
endif

" Let fzf ignore the files which is ignored by gitignore or hgignore
if executable("ag") == 1
  let $FZF_DEFAULT_COMMAND='ag -g ""'
endif
if executable('rg')
  let &grepprg = "rg --vimgrep"
  let $FZF_DEFAULT_COMMAND = 'rg --files --hidden'
endif

let $BROWSER='w3m'
let $IN_VIM=1

let g:MYVIMRC_DIR = fnamemodify(expand('$MYVIMRC'), ':h')
let $PATH .= ':' . fnamemodify(expand('$MYVIMRC'), ':h') . '/bin'

let g:floaterm_wintype='split'
let g:floaterm_position='top'
let g:floaterm_width=1.0
let g:floaterm_height=0.5
let g:floaterm_autoinsert = v:false

" Autocmd

function! WinLeaveAction()
  if &filetype=='fzf' | wincmd q
  endif
endfunction

augroup basic
  autocmd!
  autocmd! TermOpen * setlocal nonu norelativenumber | setlocal signcolumn=no
  autocmd! WinLeave * call WinLeaveAction()
  autocmd! BufWritePost worksapce.vim source workspace.vim
  autocmd! BufWritePost /tmp/*.nu set bufhidden=delete
  autocmd! BufRead /tmp/*.nu nnoremap <buffer> <c-s> <cmd>wq<cr> | inoremap <buffer> <c-s> <cmd>wq<cr> 

  au! BufRead */tasks/*.yaml,*/tasks/*.yml set ft=yaml.ansible
  au! BufRead *.yaml,*.yml if search('hosts:\|tasks:\|roles:', 'nw') | set ft=yaml.ansible | endif
  auto WinEnter * silent lua UpdateTitleString()
augroup end

augroup Binary
  au!
  au! BufReadPre  *.bin let &bin=1
  au! BufReadPost *.bin if &bin | %!xxd
  au! BufReadPost *.bin set ft=xxd | endif
  au! BufWritePre *.bin if &bin | %!xxd -r
  au! BufWritePre *.bin endif
  au! BufWritePost *.bin if &bin | %!xxd
  au! BufWritePost *.bin set nomod | endif
augroup END

command! ClearBuffer bufdo if ((expand("%p") == '' || !filereadable(expand("%p"))) && &modified == 0) | bdelete | endif

"Quit
command! Q execute "quit!"
command! Qa execute "quitall!"

" Sudo to write
command! W :w !sudo tee % >/dev/null

command! Cd1 :cd ..
command! Cd2 :cd ../..
command! Cd3 :cd ../../..
command! E :Explore

" Diff between the curret buffer and the file.
com! Diff call s:DiffWithSaved()

function! OpenChangedFiles()
  only " Close all windows, unless they're modified
  let status = system('git status -s | grep "^ \?\(M\|A\)" | cut -d " " -f 3')
  let filenames = split(status, "\n")

  if len(filenames) < 1
    let status = system('git show --pretty="format:" --name-only')
    let filenames = split(status, "\n")
  endif

  exec "edit " . filenames[0]

  for filename in filenames[1:]
    if len(filenames) > 4
      exec "tabedit " . filename
    else
      exec "sp " . filename
    endif
  endfor
endfunction
command! OpenChangedFiles :call OpenChangedFiles()

command! Enc execute '%!openssl enc -aes-256-cbc -a -salt -pass file:$HOME/.ssh/passwd.txt'
command! Enc1 execute '%!openssl enc -pbkdf2 -a -salt -pass file:$HOME/.ssh/passwd.txt'
command! Dec execute '%!openssl enc -d -aes-256-cbc -a -salt -pass file:$HOME/.ssh/passwd.txt'
command! Dec1 execute '%!openssl enc -d -pbkdf2 -a -salt -pass file:$HOME/.ssh/passwd.txt'

command! Vifm FloatermNew vifm -c only
command! NNN FloatermNew nnn
command! FFF FloatermNew fff

command! -bang -nargs=* NoteSearch
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>).' ~/notes', 1,
  \   fzf#vim#with_preview(), <bang>0)

command! Note :Files ~/notes

command! DisableTmuxKey
         \ call jobstart('set-tmux-prefix -k F1 -t 20', {
         \    'on_exit': { j,d,e ->
         \       execute('echom "enable tmux key"', '')
         \    }
         \ })

let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
let g:fzf_colors = {'gutter': ['bg', 'Normal']}
let g:fzf_floaterm_newentries = {
  \ '+root' : {
    \ 'title': 'Root Shell',
    \ 'cmd': 'sudo sh' },
  \ }
let g:mkdx#settings = { 'map': { 'enable': 1, 'prefix': '<leader>md' }, 'checkbox': { 'toggles': [' ', 'x'] } }

" Results:  :copen, :cn, :cp
" Ex: :grep -f c++/comments %
" Ex: :grep -tc++ FIXME
if executable('ugrep')
    set grepprg=ugrep\ -RInk\ -j\ -u\ --tabs=1\ --ignore-files
    set grepformat=%f:%l:%c:%m,%f+%l+%c+%m,%-G%f\\\|%l\\\|%c\\\|%m
endif

" Yank to system clipboard with Y
nnoremap yy yy
vnoremap y y
nnoremap YY "+yy
nnoremap Y "+y
vnoremap Y "+y

silent! source ~/.vim_custom.vim

" hightlight
"highlight! link HopNextKey Error
"highlight! link HopNextKey1 Error
"highlight! link HopNextKey2 Error
"highlight! link WinSeparator Boolean

nnoremap H :tabprevious<cr>
nnoremap L :tabnext<cr>
nnoremap ; :

function GoHint()
  if &filetype == 'neo-tree'
    execute 'HopLine'
  else
    execute 'HopWord'
  endif
endfunction
nnoremap <silent> s <cmd>call GoHint()<cr>

"bash like keybinding
" <c-a> for <home>, <c-e> for <end>
" <c-d> for <delete>,
" <c-h> will be overrided for <left>
inoremap <c-a> <home>
inoremap <c-e> <end>

cnoremap <silent> <c-e> <Esc>:History:<cr>

nnoremap <m-f> <c-w>w

nnoremap <C-j> <PageDown>
nnoremap <C-k> <PageUp>

cnoremap <c-h> <Left>
cnoremap <c-j> <Down>
cnoremap <c-k> <Up>
cnoremap <c-l> <Right>

nnoremap <c-g> <c-b>

" For hterm in tab
inoremap <c-h> <Left>
inoremap <c-j> <Down>
inoremap <c-k> <Up>
inoremap <c-l> <Right>
tnoremap <c-h> <Left>
tnoremap <c-j> <Down>
tnoremap <c-k> <Up>
tnoremap <c-l> <Right>

function TreeToggle()
  if len(getbufinfo({'buflisted': 1})) == 0
    return
  elseif exists(":Neotree")
    execute "Neotree toggle"
  elseif exists(":NvimTreeToggle")
    execute "NvimTreeToggle"
  elseif exists(":NERDTreeToggle")
    execute "NERDTreeToggle"
  endif
endfunction
nnoremap <c-n> :call TreeToggle()<cr>
nnoremap <c-t> :tabnew %<CR>
inoremap <c-t> <Esc>:tabnew %<CR>

nnoremap <c-e> <cmd> lua FzfLua.commands()<cr>

nnoremap <m-s> <cmd>AerialToggle<cr>

" save
nnoremap <c-s> <cmd>w<cr>
inoremap <c-s> <cmd>w<cr><esc>

inoremap <expr> <Esc>      pumvisible() ? "\<C-e>" : "\<Esc>"
inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"
inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"
inoremap <expr> <PageDown> pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<PageDown>"
inoremap <expr> <PageUp>   pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<PageUp>"

" Insert mode completion
imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)

cnoremap <c-s> e oil-ssh://

tnoremap <c-]> <cmd>stopinsert<cr>

inoremap <c-]> <Esc>
vnoremap <c-]> <Esc>
cnoremap <c-]> <Esc>
nnoremap <c-]> <Esc>

" If we need Esc in terminal buffer,
" just unmap it.
tnoremap <expr> <silent> <Esc> &filetype=='fzf' ? '<C-\><C-n>:close<cr>' : '<C-\><C-n>'
"tunmap <Esc> <C-\><C-n>

vnoremap > >gv
vnoremap < <gv

" Copy to clipboard (this is for wsl)
vnoremap <C-c> y:new ~/.vimbuffer<CR>VGp:x<CR> \| :!cat ~/.vimbuffer \| clip.exe <CR><CR>

" Bash-like movement
inoremap <c-d> <Delete>

nmap  -  <Plug>(choosewin)
nnoremap <leader>et :tabnew<cr>:read !grep # -P -e<space>

cnoremap <m-h> <Left>
cnoremap <m-j> <Down>
cnoremap <m-k> <Up>
cnoremap <m-l> <Right>

" Paste text
inoremap <C-v> <Esc>pi

" Paste text from clipboard
vnoremap <c-c> "+y
vnoremap <Return> "+y

"Quickly move current line
nnoremap [e  :<c-u>execute 'move -1-'. v:count1<cr>
nnoremap ]e  :<c-u>execute 'move +'. v:count1<cr>

nnoremap zz za
nnoremap Q :qa<cr>

" Exit vim quickly
nnoremap <c-c> :qa!

" Since I use hterm in tab, I need another key for <c-w>
imap <m-bs> <c-w>
nmap <m-bs> <c-w>
tmap <m-bs> <c-w>

tnoremap <Insert> <C-\><C-n>
"tnoremap <C-[> <C-\><C-n> Don't enable this. Esc is useful when vim in vim
tnoremap <m-h> <C-\><C-n><C-w>h
tnoremap <m-j> <C-\><C-n><C-w>j
tnoremap <m-k> <C-\><C-n><C-w>k
tnoremap <m-l> <C-\><C-n><C-w>l
nnoremap <m-h> <C-w>h
nnoremap <m-j> <C-w>j
nnoremap <m-k> <C-w>k
nnoremap <m-l> <C-w>l
inoremap <m-h> <Esc><C-w>h
inoremap <m-j> <Esc><C-w>j
inoremap <m-k> <Esc><C-w>k
inoremap <m-l> <Esc><C-w>l

imap <m-p> <c-p>
nmap <m-p> <c-p>
tmap <m-p> <c-p>
cmap <m-p> <c-p>
nmap <m-n> <c-n>
imap <m-n> <c-n>
tmap <m-n> <c-n>
cmap <m-n> <c-n>

inoremap <m-o> <cmd>lua FzfBuffer()<cr>
nnoremap <m-o> <cmd>lua FzfBuffer()<cr>
tnoremap <m-o> <cmd>lua FzfBuffer()<cr>

inoremap <m-y> <cmd>lua GoToMainWindowAndRunCommand("FzfLua jumps")<cr>
nnoremap <m-y> <cmd>lua GoToMainWindowAndRunCommand("FzfLua jumps")<cr>
tnoremap <m-y> <cmd>lua GoToMainWindowAndRunCommand("FzfLua jumps")<cr>

inoremap <m-i> <cmd>lua RegistersInsert()<cr>
nnoremap <m-i> <cmd>lua RegistersInsert()<cr>
tnoremap <m-i> <cmd>lua RegistersInsert()<cr>

function! CallHistoryShell()
  execute feedkeys("fzf-history-widget")
  execute feedkeys("\<CR>")
  if mode() != 't'
    startinsert
  endif
endfunction
function! FuncAltU()
  if mode() == 't' || &filetype=='floaterm'
    call CallHistoryShell()
  else
    lua GoToMainWindowAndRunCommand('lua require("fzf-lua").grep({ search = "",continue_last_search = true,multiprocess=true })')
  end
endfunction

inoremap <m-u> <cmd>call FuncAltU()<cr>
nnoremap <m-u> <cmd>call FuncAltU()<cr>
tnoremap <m-u> <cmd>call FuncAltU()<cr>
vnoremap <m-u> "ry:<c-u>FzfLua grep<cr> <c-r>r<cr>



inoremap <m-U> <cmd>FzfLua live_grep_resume<cr>
nnoremap <m-U> <cmd>FzfLua live_grep_resume<cr>

" buufer switch
nnoremap <expr> <m-d> &filetype=="floaterm" ? ":FloatermPrev<cr>" : "<c-^>"
inoremap <m-d> <Esc><c-^>a
tnoremap <m-d> <C-\><C-n>:FloatermNext<cr>i

imap <m-w> <c-w>
nmap <m-w> <c-w>
tmap <m-w> <c-w>
cmap <m-w> <c-w>
vmap <m-w> <c-w>

" Paste text
tnoremap <m-v> <C-\><C-n>pi
inoremap <m-v> <Esc>pi

tnoremap <m-r> <cmd>lua RunPreviousCommandFunc()<cr>
nnoremap <m-r> <cmd>lua RunPreviousCommandFunc()<cr>
inoremap <m-r> <cmd>lua RunPreviousCommandFunc()<cr>

tnoremap <m-v> <c-v>
nnoremap <m-v> <c-v>
inoremap <m-v> <c-v>
cnoremap <m-v> <c-v>

function! EnterShellFunc()
  let mod = mode()
  if mod == 'n'
    execute 'FloatermShow'
    execute feedkeys("i", "t")
  elseif mod == 'i'
    execute 'FloatermShow'
    if &filetype != 'floaterm'
      execute "FloatermToggle"
    endif
    execute feedkeys("i", "t")
  endif
endfunction

nnoremap <m-e> <cmd>lua RunCurrentLine()<cr>
inoremap <m-e> <cmd>lua RunCurrentLine()<cr>

imap <m-g> <cmd>lua require('winpick').select()<cr>
nmap <m-g> <cmd>lua require('winpick').select()<cr>
tmap <m-g> <cmd>lua require('winpick').select()<cr>

inoremap <m-m> <Esc>:Marks<cr>
nnoremap <m-m> :Marks<cr>

inoremap <m-:> <cmd>FloatermNew<cr>
nnoremap <m-:> <cmd>FloatermNew<cr>
tnoremap <m-:> <cmd>FloatermNew<cr>

inoremap <m-;> <cmd>lua TermToggle()<cr>
nnoremap <m-;> <cmd>lua TermToggle()<cr>
tnoremap <m-;> <cmd>lua TermToggle()<cr>

inoremap <silent> <m-'> <cmd>lua FloatermNext(1)<cr>
nnoremap <silent> <m-'> <cmd>lua FloatermNext(1)<cr>
tnoremap <silent> <m-'> <cmd>lua FloatermNext(1)<cr>

inoremap <silent> <m-"> <cmd>lua FloatermNext(-1)<cr>
nnoremap <silent> <m-"> <cmd>lua FloatermNext(-1)<cr>
tnoremap <silent> <m-"> <cmd>lua FloatermNext(-1)<cr>

inoremap <expr> <silent> <m-"> &filetype=='floaterm' ? '<cmd>FloatermPrev<cr>' : '<cmd>FloatermPrev<cr><cmd>wincmd w<cr>'
nnoremap <expr> <silent> <m-"> &filetype=='floaterm' ? '<cmd>FloatermPrev<cr>' : '<cmd>FloatermPrev<cr><cmd>wincmd w<cr>'
tnoremap <silent> <m-"> <c-\><c-n>:FloatermPrev<cr>

inoremap <silent> <m-Enter> <Esc>:FloatermSend<cr>
nnoremap <silent> <m-Enter> :FloatermSend<cr>
" tnoremap <silent> <m-Enter> <c-\><c-n>:FloatermSend<cr> " needed by br
vnoremap <silent> <m-Enter> :FloatermSend<cr>

inoremap <silent> <s-a-enter> <Esc>:%FloatermSend<cr>
nnoremap <silent> <s-a-enter> :%FloatermSend<cr>

inoremap <m-]> <cmd>lua NextItem(1)<cr>
nnoremap <m-]> <cmd>lua NextItem(1)<cr>
tnoremap <m-]> <cmd>lua NextItem(1)<cr>
inoremap <m-[> <cmd>lua NextItem(-1)<cr>
nnoremap <m-[> <cmd>lua NextItem(-1)<cr>
tnoremap <m-[> <cmd>lua NextItem(-1)<cr>
inoremap <m-\> <cmd>lua NextItem(1)<cr>
nnoremap <m-\> <cmd>lua NextItem(1)<cr>
tnoremap <m-\> <cmd>lua NextItem(1)<cr>
inoremap <c-\> <cmd>lua NextItem(-1)<cr>
nnoremap <c-\> <cmd>lua NextItem(-1)<cr>
tnoremap <c-\> <cmd>lua NextItem(-1)<cr>

function ResizeWin()
  resize +2000
endfunction

inoremap <m-q> <cmd>call jobstart('workspace')<cr>
nnoremap <m-q> <cmd>call jobstart('workspace')<cr>
tnoremap <m-q> <cmd>call jobstart('workspace')<cr>

nnoremap <m-`> :call jobstart('workspace')<cr>

nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> gi <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> [d <cmd>lua vim.diagnostic.goto_prev({severity=vim.diagnostic.severity.INFO})<CR>
nnoremap <silent> ]d <cmd>lua vim.diagnostic.goto_next({severity=vim.diagnostic.severity.INFO})<CR>

lua <<EOF
function SetKeymap(modes, key, cmd, desc)
  for _, v in pairs(modes) do
    vim.api.nvim_set_keymap(v, key, cmd, {
      noremap = true,
      desc = desc,
      nowait = true,
      silent = true,
    })
  end
end
EOF
nnoremap <silent> . <cmd>FzfLua buffers<cr>

nnoremap D <cmd>lua vim.diagnostic.open_float()<cr>

nnoremap <silent> <leader>zlp <cmd>FzfLua Lines<cr>
nnoremap <silent> <leader>zlb <cmd>FzfLua BLines<cr>
nnoremap <silent> <leader>zgb <cmd>FzfLua git_branches<cr>
nnoremap <silent> <leader>zgs <cmd>FzfLua git_status<cr>
nnoremap <silent> <leader>zgh <cmd>FzfLua git_stash<cr>
nnoremap <silent> <leader>zgcp <cmd>FzfLua git_commits<cr>
nnoremap <silent> <leader>zgcb <cmd>FzfLua git_bcommits<cr>
nnoremap <silent> <leader>zhf <cmd>FzfLua oldfiles<cr>
nnoremap <silent> <leader>zhc <cmd>FzfLua command_history<cr>
nnoremap <silent> <leader>zhs <cmd>FzfLua search_history<cr>
nnoremap <silent> <leader>zm <cmd>FzfLua Marks<cr>
nnoremap <silent> <leader>zf <cmd>FzfLua frecency<cr>
nnoremap <silent> <leader>zo <cmd>FzfLua buffers<cr>
nnoremap <silent> <leader>zr <cmd>FzfLua live_grep<cr>

xmap ga <Plug>(EasyAlign)

nnoremap <silent> <leader>gam <cmd>FloatermNew git commit --amend<CR>
nnoremap <silent> <leader>gbl <cmd>Git blame<CR>
nnoremap <silent> <leader>gbr <cmd>FzfLua git_branches<cr>
nnoremap <silent> <leader>gc <cmd>FloatermNew git commit -S<CR>
nnoremap <silent> <leader>gdc <cmd>Git diff %<CR>
nnoremap <silent> <leader>gdi <cmd>Git diff<CR>
nnoremap <silent> <leader>gdl <cmd>Git diff @~..@<CR>
nnoremap <silent> <leader>gds <cmd>Git diff --cached<CR>
nnoremap <silent> <leader>ge <cmd>Gedit<CR>
nnoremap <silent> <leader>gi <cmd>Git add -p %<CR>
nnoremap <silent> <leader>glb <cmd>FzfLua git_bcommits<cr>
nnoremap <silent> <leader>glp <cmd>FzfLua git_commits<cr>
lua SetKeymap({'n'}, '<leader>grb', '<cmd>Gread<cr>', 'restore file, buffer only')
lua SetKeymap({'n'}, '<leader>gre', '<cmd>Git checkout %<cr>', 'restore file from git')
lua SetKeymap({'n'}, '<leader>grs', '<cmd>Git restore --staged %<cr>', 'restore file from staged')
nnoremap <silent> <leader>gp <cmd>lua KillAndRerunTermWrapper("git push", {shell=true})<cr>
nnoremap <silent> <leader>gs <cmd>FzfLua git_status<cr>
nnoremap <silent> <leader>gu <cmd>Git pull --rebase<CR>
nnoremap <silent> <leader>gw <cmd>Gwrite<CR>
nnoremap <silent> <leader>ggpl <cmd>Octo pr list<cr>
nnoremap <silent> <leader>ggpc <cmd>Octo pr create<cr>
nnoremap <silent> <leader>ggpm <cmd>Octo pr merge<cr>
nnoremap <silent> <leader>ggpe <cmd>Octo pr edit<cr>
nnoremap <silent> <leader>ggpu <cmd>Octo pr url<cr>
nnoremap <silent> <leader>ggpo <cmd>Octo pr checkout<cr>

nnoremap <silent> <leader>id :put =strftime('%Y-%m-%d')<cr>
nnoremap <silent> <leader>it :put =strftime('%H:%M:%S')<cr>
nnoremap <silent> <leader>ic :colorscheme<cr>

" Disable highlight
nnoremap <silent> <leader>sh :noh<cr>

function TabCD()
  execute "tabnew %"
  execute "tcd %:p:h"
endfunction
nnoremap <Leader>cd :call TabCD()<cr>
nnoremap <leader>cc :lua RunShellAndShow('')<left><left>
nnoremap <leader>cz <cmd>Zi<cr>
"nnoremap <leader>co  " for rnadom colorscheme

nnoremap <leader>fx :Explore<space>
nnoremap <leader>fr :e oil-ssh://
nnoremap <silent> <leader>fb :Rexplore<CR>
nnoremap <silent> <leader>fv :Vaffle<CR>
nnoremap <silent> <leader>fs :w<CR>
nnoremap <silent> <leader>fi :call FindFileInTree()<CR>
nnoremap <leader>fe :edit <c-r>=expand("%:p:h")<cr>/
nnoremap <leader>ft :call TreeToggle()<cr>

" Tab mappings
nnoremap <silent> <leader>ta :tabnew<cr>
nnoremap <silent> <leader>to :tabonly<cr>
nnoremap <silent> <leader>tc :tabclose<cr>
nnoremap <silent> <leader>tm :tabmove
nnoremap <silent> <leader>tp :tcd <c-r>=expand("%:p:h")<cr><cr>

" Tab mappings
function! NameTerminalBuffer(name)
  let l:path = expand("%:p")
  let l:parts = split(l:path, "#")
  let l:newPath = substitute(l:parts[0], '^\s*\(.\{-}\)\s*$', '\1', '')
  execute "keepalt file" l:newPath '\#'.a:name
endfunction
nnoremap <leader>tn :call NameTerminalBuffer('')<left><left>

" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
nnoremap <silent> <leader>te :tabedit %<cr>

" Open vimgrep and put the cursor in the right position
"nnoremap <leader>gv :vimgrep // **/* <left><left><left><left><left><left><left>

" Vimgreps in the current file
"nnoremap <leader><space> :vimgrep // <Home><right><right><right><right><right><right><right><right><right>

" close buffer/window
nnoremap <silent> <leader>qq :Bclose<cr>:q<cr>
nnoremap <silent> <leader>qw :q<cr>
nnoremap <silent> <leader>qb :Bclose<cr>
nnoremap <silent> <leader>qt :tabclose<cr>
nnoremap <silent> <leader>qa :qa!<cr>
nnoremap <silent> <leader>qx <cmd>bufdo bd<cr>
nnoremap <silent> <leader>qs <cmd>lua require("persistence").load()<cr>

" State / Switch
function ToggleIndentLine()
  if exists(":IndentLinesToggle")
    execute "IndentLinesToggle"
  elseif exists(":IndentBlanklineToggle")
    execute ":IndentBlanklineToggle"
  endif
endfunction

nnoremap <silent> <leader>sd <cmd>lua ToggleDark()<cr>
nnoremap <silent> <leader>sn :set nu!<cr>
nnoremap <silent> <leader>sw :set wrap!<cr>
nnoremap <silent> <leader>sp :set paste!<cr>
nnoremap <silent> <leader>sm <cmd>lua ToggleMouse()<cr>
nnoremap <silent> <leader>ss <cmd>lua ToggleStatusLine()<cr>
nnoremap <silent> <leader>sl <cmd>lua ToggleIndentLine()<cr>
nnoremap <silent> <leader>si :source Session.vim<cr>
nnoremap <silent> <leader>se :mksession!<cr>
nnoremap <silent> <leader>sc <cmd>lua ToggleForCopy()<cr>
nnoremap <silent> <leader>st :Switch<cr>
nnoremap <silent> <leader>sk :DisableTmuxKey<cr>
nnoremap <silent> <leader>so :TSContextToggle<cr>
nnoremap <silent> <leader>sg :set guicursor=<cr>
nnoremap <silent> <expr> <leader>sb &background=='light' ? ":set background=dark<cr>" : ":set background=light<cr>"

nnoremap <silent> <leader>br :redraw<cr>

nnoremap <silent> <leader>mm :Marks<cr>
nnoremap <silent> <leader>mn ]`
nnoremap <silent> <leader>mp [`
nnoremap <silent> <leader>mc :delmarks!<cr>
nnoremap <silent> <leader>md :delmarks!<cr>
nnoremap <silent> <leader>mg `.

nnoremap <silent> <leader>nl :Note<cr>
nnoremap <silent> <leader>ns :NoteSearch<cr>

" Gina
nnoremap <leader>vs :Gina status<cr>
nnoremap <leader>vu :Gina pull<cr>
nnoremap <leader>vp :Gina push<cr>
nnoremap <leader>vf :Gina fetch<cr>
nnoremap <leader>vd :Gina diff<cr>
nnoremap <leader>vl :Gina log<cr>
nnoremap <leader>vc :Gina commit<cr>
nnoremap <leader>va :Gina add<space>
nnoremap <leader>vt :Gina tag<cr>
nnoremap <leader>vb :Gina branch<cr>
nnoremap <leader>vv :Gina<space>
nnoremap <leader>vi :lua RunShellAndShow('git add -p %:p')<cr>

nnoremap <silent> <leader>wt :ToggleWorkspace<CR>
nnoremap <silent> <leader>wr :WinResizerStartResize<cr>
nnoremap <silent> <leader>wm :WinResizerStartMove<cr>
nnoremap <silent> <leader>wf :WinResizerStartFocus<cr>
nnoremap <silent> <leader>wsh :split<cr>
nnoremap <silent> <leader>wsv :vsplit<cr>
nnoremap <silent> <leader>wqa :wqa<cr>

nnoremap <silent> <leader>wh :wincmd h<cr>
nnoremap <silent> <leader>wj :wincmd j<cr>
nnoremap <silent> <leader>wk :wincmd k<cr>
nnoremap <silent> <leader>wl :wincmd l<cr>

vnoremap <leader>e <cmd>lua require("escape").escape()<cr>
nnoremap <leader>ecw ggVG"+y
nnoremap <silent> <leader>ed :e <c-r>=expand("%:p:h")<cr>/<cr>
nnoremap <silent> <leader>eu :UndotreeToggle<cr>
nnoremap <silent> <leader>esi <cmd>lua EditFile(vim.env.MYVIMRC)<cr>
nnoremap <silent> <leader>esl <cmd>lua EditFile('~/.vim_custom.vim')<cr>
nnoremap <silent> <leader>esc <cmd>lua EditFile('~/.config/nvim/nvim.vim')<cr>
nnoremap <silent> <leader>esj <cmd>call EditTodayNote()<cr>
nnoremap <silent> <leader>esd <cmd>e .<cr>
nnoremap <silent> <leader>er :registers<cr>
nnoremap <leader>ef :set filetype=
nnoremap <leader>ea :filetype detect<cr>
nnoremap <silent> <leader>eg :Grepper<cr>
nnoremap <silent> <leader>ej ::%!jq '.'<cr>
nnoremap <leader>ee :terminal<space>
nnoremap <leader>ec <cmd>FzfLua changes<cr>
nnoremap <leader>ej <cmd>FzfLua jumps<cr>

nnoremap <silent> <leader>en :echo getcwd()<cr>
nnoremap <silent> <leader>em :Pushd <c-r>=expand("%:p:h")<cr><cr>
nnoremap <silent> <leader>ecr :let @a=@%<cr>
nnoremap <silent> <leader>ecn :let @a=expand("%:t")<cr>
nnoremap <silent> <leader>ecf :let @a=expand("%:p")<cr>
nnoremap <silent> <leader>ecd :let @a=expand("%:p:h")<cr>

nnoremap <silent> <leader>pp :put<cr>
nnoremap <silent> <leader>pr :put<cr>G$a<cr>
nnoremap <leader>pi :lua KillAndRerunTerm("PlugInstall", "nvim '+silent! PlugInstall' '+silent! TSUpdateSync' +qall")<cr>
nnoremap <leader>pu :lua KillAndRerunTerm("PlugUpdate", "nvim '+silent! PlugUpgrade' '+silent! PlugUpdate' '+silent! TSUpdateSync' +qall")<cr>

" Run/Test
nnoremap <silent> <leader>rt :TestNearest<cr>
nnoremap <silent> <leader>rs :TestSuite<cr>
nnoremap <silent> <leader>rf :TestFile<cr>
nnoremap <silent> <leader>rr :History:<cr>
nnoremap <silent> <leader>rbc <cmd>lua RunBuffer()<cr>
nnoremap <silent> <leader>rbv <cmd>lua RunBuffer({new=true})<cr>
nnoremap <leader>rc ::%FloatermSend<cr>
nnoremap <leader>rh :call Ssh('',[])<left><left><left><left><left>

nnoremap <silent> <leader>o0 :set foldlevel=0<CR>
nnoremap <silent> <leader>o1 :set foldlevel=1<CR>
nnoremap <silent> <leader>o2 :set foldlevel=2<CR>
nnoremap <silent> <leader>o3 :set foldlevel=3<CR>
nnoremap <silent> <leader>o4 :set foldlevel=4<CR>
nnoremap <silent> <leader>o5 :set foldlevel=5<CR>
nnoremap <silent> <leader>o6 :set foldlevel=6<CR>
nnoremap <silent> <leader>o7 :set foldlevel=7<CR>
nnoremap <silent> <leader>o8 :set foldlevel=8<CR>
nnoremap <silent> <leader>o9 :set foldlevel=9<CR>
nnoremap <silent> <leader>oo zR<CR>
nnoremap <silent> <leader>oc zM<CR>


" open new terminal in new tab/buffer.
nnoremap <silent> <leader>tt :tabnew <cr>:terminal<cr>
nnoremap <leader>tb :lua KillAndRerunTermWrapper('')<left><left>
nnoremap <silent> <leader>tv :vsplit<cr><c-w>l:terminal<cr>


" Remap for do codeAction of current line
nnoremap <leader>aj :AnyJump<CR>
nnoremap <leader>ab :AnyJumpBack<CR>
nnoremap <leader>al :AnyJumpLastResults<CR>

nnoremap <silent> <leader>lwa <cmd>lua vim.lsp.buf.add_workspace_folder()<cr>
nnoremap <silent> <leader>lwr <cmd>lua vim.lsp.buf.remove_workspace_folder()<cr>
nnoremap <silent> <leader>lwl <cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<cr>
nnoremap <silent> <leader>ldt <cmd>lua vim.lsp.buf.type_definition()<cr>
nnoremap <silent> <leader>lde <cmd>lua vim.lsp.buf.definition()<cr>
nnoremap <silent> <leader>ldE <cmd>lua vim.lsp.buf.declaration_call()<cr>
nnoremap <silent> <leader>ldf <cmd>lua vim.diagnostic.open_float()<CR>
nnoremap <silent> <leader>ldl <cmd>lua vim.diagnostic.setqflist()<CR>
nnoremap <silent> <leader>ldn <cmd>lua vim.diagnostic.goto_next()<CR>
nnoremap <silent> <leader>ldp <cmd>lua vim.diagnostic.goto_prev()<CR>
nnoremap <silent> <leader>lrn <cmd>Lspsaga rename<cr>
nnoremap <silent> <leader>la <cmd>lua vim.lsp.buf.code_action()<cr>
nnoremap <silent> <leader>lre <cmd>lua vim.lsp.buf.references()<cr>
nnoremap <silent> <leader>lf <cmd>lua vim.lsp.buf.format { async = true }<cr>
vnoremap <silent> <leader>lf <cmd>lua vim.lsp.buf.range_formatting()<cr>
vnoremap <silent> f <cmd>lua vim.lsp.buf.range_formatting()<cr>
nnoremap <silent> <leader>li <cmd>lua require'fzf_lsp'.implementation_call()<cr>
nnoremap <silent> <leader>lsa <cmd>lua vim.lsp.buf.signature_help()<cr>
nnoremap <silent> <leader>lsy <cmd>lua require'fzf_lsp'.document_symbol_call()<cr>
nnoremap <silent> <leader>lsY <cmd>lua require'fzf_lsp'.workspace_symbol_call()<cr>
nnoremap <silent> <leader>lsc <cmd>lua require'fzf_lsp'.incoming_calls_call()<cr>
nnoremap <silent> <leader>lsC <cmd>lua require'fzf_lsp'.outcoming_calls_call()<cr>
nnoremap <silent> <leader>lc <cmd>lua SwitchWordCase()<cr>

nnoremap <leader>lsg :FloatermNew! curl 'cht.sh/<c-r>=&filetype<cr>/'<left>
nnoremap <silent> <leader>lsw :ISwap<cr>
nnoremap <silent> <leader>ltf :TestFile<cr>
nnoremap <silent> <leader>ltn :TestNearest<cr>
nnoremap <silent> <leader>lts :TestSuite<cr>
nnoremap <silent> <leader>ltv :TestVisit<cr>
nnoremap <leader>lg <cmd>Neogen<cr>

nnoremap <silent> <leader>lel :LeetCodeList<cr>
nnoremap <silent> <leader>les :LeetCodeSubmit<cr>
nnoremap <silent> <leader>let :LeetCodeTest<cr>

nnoremap <silent> <localleader>dt <cmd>lua require'dap'.toggle_breakpoint()<cr>
nnoremap <silent> <localleader>dc <cmd>lua require'dap'.continue()<cr>
nnoremap <silent> <localleader>di <cmd>lua require'dap'.step_into()<cr>
nnoremap <silent> <localleader>do <cmd>lua require'dap'.step_over()<cr>
nnoremap <silent> <localleader>dr <cmd>lua require'dap'.repl.open()<cr>
nnoremap <silent> <localleader>dr <cmd>lua require("dapui").toggle()<cr>

nnoremap <silent> <localleader>a :Ag<cr>
nnoremap <silent> <localleader>b :b#<cr>
nnoremap <silent> <localleader>c <cmd>Telescope<cr>
nnoremap <silent> <localleader>g :ChooseWin<cr>
nnoremap <silent> <localleader>t :tabnew %<cr>
nnoremap <silent> <localleader>h :wincmd h<cr>
nnoremap <silent> <localleader>j :wincmd j<cr>
nnoremap <silent> <localleader>k :wincmd k<cr>
nnoremap <silent> <localleader>l :wincmd l<cr>
nnoremap <silent> <localleader>y <cmd>lua GoToMainWindowAndRunCommand("FzfLua jumps")<cr>
nnoremap <silent> <localleader>o <cmd>lua GoToMainWindowAndRunCommand("FzfLua buffers")<cr>
nnoremap <silent> <localleader>p <cmd>lua FindFileCwd()<cr>
nnoremap <silent> <localleader>qq :q!<cr>
nnoremap <silent> <localleader>qs :wq!<cr>
nnoremap <silent> <localleader>n <cmd>call TreeToggle()<cr>
nnoremap <silent> <localleader>tt <cmd>lua TermToggle()<cr>
nnoremap <silent> <localleader>tj <cmd>lua FloatermNext(1)<cr>
nnoremap <silent> <localleader>tk <cmd>lua FloatermNext(-1)<cr>
nnoremap <silent> <localleader>tn <cmd>FloatermNew<cr>
nnoremap <silent> <localleader>rp <cmd>lua RunPreviousCommandFunc()<cr>
nnoremap <silent> <localleader>; <cmd>lua TermToggle()<cr>
nnoremap <silent> <localleader>' <cmd>lua FloatermNext(1)<cr>
nnoremap <localleader>rr :lua KillAndRerunTermWrapper('')<left><left>
nnoremap <localleader>rn <cmd>exec 'FloatermNew --autoclose=1 '. getline('.')<cr>
nnoremap <localleader>re :lua KillAndRerunTermWrapper<up>
nnoremap <localleader>e <cmd>lua RunBuffer()<cr>

xnoremap iu :lua require"treesitter-unit".select()<CR>
xnoremap au :lua require"treesitter-unit".select(true)<CR>
onoremap iu :<c-u>lua require"treesitter-unit".select()<CR>
onoremap au :<c-u>lua require"treesitter-unit".select(true)<CR>

nnoremap <leader>dg :silent exec '!bb "go <c-r>=&filetype<cr><space>"'<left><left>
nnoremap <leader>dd :silent exec '!bb "https://devdocs.io/<c-r>=&filetype<cr>"'<cr>
