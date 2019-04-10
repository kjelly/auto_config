" Use normal regex
" http://stevelosh.com/blog/2010/09/coming-home-to-vim
nnoremap / /\v
vnoremap / /\v

" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :call VisualSelection('f')<CR>
vnoremap <silent> # :call VisualSelection('b')<CR>

" Smart way to move between windows
nnoremap <C-h> <C-W>h
nnoremap <C-j> <C-W>j
nnoremap <C-k> <C-W>k
nnoremap <C-l> <C-W>l

cnoremap <c-h> <Left>
cnoremap <c-j> <Down>
cnoremap <c-k> <Up>
cnoremap <c-l> <Right>

nnoremap <C-n> :NERDTreeTabsToggle<CR>
nnoremap <C-t> :tabnew %<CR>
inoremap <C-t> <Esc>:tabnew %<CR>
noremap H gT
noremap L gt

" Command
nnoremap <C-e> :Commands<cr>

" Tag list
nnoremap <C-s> :Tagbar<cr>

inoremap <C-s> <Esc>:w<cr>a

inoremap <expr> <Esc>      pumvisible() ? "\<C-e>" : "\<Esc>"
inoremap <expr> <CR>       pumvisible() ? "\<C-y>" : "\<CR>"
inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"
inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"
inoremap <expr> <PageDown> pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<PageDown>"
inoremap <expr> <PageUp>   pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<PageUp>"

" Find file/buffer
nnoremap <C-p> :Files<cr>

" Insert mode completion
imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)

cnoremap <c-s> Explore scp://

" Use Enter to expand snippet. This is for nvim-completion-manager.
"imap <expr> <CR>  (pumvisible() ?  "\<c-y>\<Plug>(expand_or_nl)" : "\<CR>")
"imap <expr> <Plug>(expand_or_nl) (cm#completed_is_snippet() ? "\<Tab>":"\<CR>")

{% if nvim %}tnoremap <C-]> <C-\><C-n>
{% endif %}
inoremap <C-]> <Esc>
nnoremap <C-]> i
vnoremap <C-]> <Esc>
cnoremap <C-]> <Esc>

nnoremap ; :

inoremap ;; <Esc>
cnoremap ;; <Esc>
vnoremap ;; <Esc>
{% if nvim %}tnoremap ;; <C-\><C-n> {% endif %}

{% if nvim %}tnoremap <Esc><Esc> <C-\><C-n> {% endif %}

vnoremap > >gv
vnoremap < <gv

nnoremap ! :!

" Copy to clipboard (this is for wsl)
vnoremap <C-c> y:new ~/.vimbuffer<CR>VGp:x<CR> \| :!cat ~/.vimbuffer \| clip.exe <CR><CR>

" Bash-like movement
inoremap <c-d> <Delete>

nmap  -  <Plug>(choosewin)
nnoremap <leader>et :tabnew<cr>:read !grep # -P -e<space>
{% if nvim %}

cnoremap <A-h> <Left>
cnoremap <A-j> <Down>
cnoremap <A-k> <Up>
cnoremap <A-l> <Right>

" Alt-num to switch tab
noremap <A-0> 0gt
noremap <A-1> 1gt
noremap <A-2> 2gt
noremap <A-3> 3gt
noremap <A-4> 4gt
noremap <A-5> 5gt
noremap <A-6> 6gt
noremap <A-7> 7gt
noremap <A-8> 8gt
noremap <A-9> 9gt
noremap <A-0> 0gt

{% else %}

" Alt-num to switch tab
execute "set <M-0>=\e0"
noremap <M-0> 0gt
execute "set <M-1>=\e1"
noremap <M-1> 1gt
execute "set <M-2>=\e2"
noremap <M-2> 2gt
execute "set <M-3>=\e3"
noremap <M-3> 3gt
execute "set <M-4>=\e4"
noremap <M-4> 4gt
execute "set <M-5>=\e5"
noremap <M-5> 5gt
execute "set <M-6>=\e6"
noremap <M-6> 6gt
execute "set <M-7>=\e7"
noremap <M-7> 7gt
execute "set <M-8>=\e8"
noremap <M-8> 8gt
execute "set <M-9>=\e9"
noremap <M-9> 9gt

{% endif %}

" Paste text
inoremap <C-v> <Esc>pi

" Paste text from clipboard
vnoremap <c-c> "+y
vnoremap <Return> "+y

"Quickly move current line
nnoremap [e  :<c-u>execute 'move -1-'. v:count1<cr>
nnoremap ]e  :<c-u>execute 'move +'. v:count1<cr>

"inoremap <C-d>     <Plug>(neosnippet_expand_or_jump)

let g:racer_cmd = "{{ HOME_PATH }}/.cargo/bin/racer"
let $RUST_SRC_PATH="{{ HOME_PATH }}/rust-src/src"

nmap <silent> s <Plug>(easymotion-bd-w)
nnoremap <silent> S :<C-u>call EasyMotion#LineAnywhere(0, 2)<CR>

nnoremap zz za
nnoremap Q :qa<cr>

if exists('g:incsearch#_go_config')
  map /  <Plug>(incsearch-forward)\v
  map ?  <Plug>(incsearch-backward)\v
  map g/ <Plug>(incsearch-stay)\v
endif

function! SwitchBuffer()
  if &buftype == 'terminal'
    wincmd k
  else
    wincmd j
  endif
endfunction

vmap <C-c> y:call SendViaOSC52(getreg('"'))<cr>

{% if nvim %}

" Since I use hterm in tab, I need another key for <c-w>
imap <a-bs> <c-w>
nmap <a-bs> <c-w>
tmap <a-bs> <c-w>

" Tab switch
tnoremap <A-1> <C-\><C-n>1gti
tnoremap <A-2> <C-\><C-n>2gti
tnoremap <A-3> <C-\><C-n>3gti
tnoremap <A-4> <C-\><C-n>4gti
tnoremap <A-5> <C-\><C-n>5gti
tnoremap <A-6> <C-\><C-n>6gti
tnoremap <A-7> <C-\><C-n>7gti
tnoremap <A-8> <C-\><C-n>8gti
tnoremap <A-9> <C-\><C-n>9gti
tnoremap <A-0> <C-\><C-n>0gti

" Tab switch
inoremap <A-1> <Esc>1gti
inoremap <A-2> <Esc>2gti
inoremap <A-3> <Esc>3gti
inoremap <A-4> <Esc>4gti
inoremap <A-5> <Esc>5gti
inoremap <A-6> <Esc>6gti
inoremap <A-7> <Esc>7gti
inoremap <A-8> <Esc>8gti
inoremap <A-9> <Esc>9gti
inoremap <A-0> <Esc>0gti

tnoremap <Insert> <C-\><C-n>
"tnoremap <C-[> <C-\><C-n> Don't enable this. Esc is useful when vim in vim
tnoremap <A-h> <C-\><C-n><C-w>h
tnoremap <A-j> <C-\><C-n><C-w>j
tnoremap <A-k> <C-\><C-n><C-w>k
tnoremap <A-l> <C-\><C-n><C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l
inoremap <A-h> <Esc><C-w>h
inoremap <A-j> <Esc><C-w>j
inoremap <A-k> <Esc><C-w>k
inoremap <A-l> <Esc><C-w>l

" Find files/buffers
function! OpenBuffer()
  let buf=bufnr('%')
  bufdo if &buftype ==# 'terminal' | silent! execute 'file' b:term_title | endif
  exec 'b' buf
  execute "Buffers"
endfunction

imap <A-p> <c-p>
nmap <A-p> <c-p>
tmap <A-p> <c-p>
cmap <A-p> <c-p>
nmap <A-n> <c-n>
imap <A-n> <c-n>
tmap <A-n> <c-n>
cmap <A-n> <c-n>

inoremap <A-o> <Esc>:Buffers<cr>
nnoremap <A-o> :Buffers<cr>
tnoremap <A-o> <C-\><C-n>:Buffers<cr>

inoremap <A-i> <Esc>:Ag<cr>
nnoremap <A-i> :Ag<cr>
tnoremap <A-i> <C-\><C-n>:Ag<cr>

inoremap <A-u> <Esc>:C g w3m<cr>
nnoremap <A-u> :C g w3m<cr>
tnoremap <A-u> <C-\><C-n>:C g w3m<cr>

" buufer switch
nnoremap <A-b> <c-^>
inoremap <A-b> <Esc><c-^>a
tnoremap <A-b> <C-\><C-n><c-^>a

nnoremap <A-d> :Denite devdocs<cr>
inoremap <A-d> <Esc>:Denite devdocs<cr>
tnoremap <A-d> <C-\><C-n>:Denite devdocs<cr>

" save
nnoremap <A-s> :w<cr>
inoremap <A-s> <Esc>:w<cr>
tnoremap <A-s> <C-\><C-n>


" Resize buffer
nnoremap <silent> <A-a>  :resize +1000<cr>
nnoremap <silent> <A-q>  :resize +1000<cr>
nnoremap <silent> <A-w>  <c-w><c-=>
nnoremap <silent> <A-e>  :resize -1000<cr>
"nnoremap <silent> <A-r>  :vertical resize +1000<cr>
"nnoremap <silent> <A-t>  :vertical resize -1000<cr>
inoremap <silent> <A-a>  <Esc>:resize +1000<cr>a
inoremap <silent> <A-q>  <Esc>:resize +1000<cr>a
inoremap <silent> <A-w>  <Esc><c-w><c-=>i
inoremap <silent> <A-e>  <Esc>:resize -1000<cr>a
"inoremap <silent> <A-r>  <Esc>:vertical resize +1000<cr>a
"inoremap <silent> <A-t>  <Esc>:vertical resize -1000<cr>a
tnoremap <silent> <A-a>  <C-\><C-n>:resize +1000<cr>a
tnoremap <silent> <A-q>  <C-\><C-n>:resize +1000<cr>a
tnoremap <silent> <A-w>  <C-\><C-n><c-w><c-=>i
tnoremap <silent> <A-e>  <C-\><C-n>:resize -1000<cr>a
"tnoremap <silent> <A-r>  <C-\><C-n>:vertical resize +1000<cr>a
"tnoremap <silent> <A-t>  <C-\><C-n>:vertical resize -1000<cr>a

" Paste text
tnoremap <A-v> <C-\><C-n>pi
inoremap <A-v> <Esc>pi

inoremap <A-r><A-r> <Esc>:C ./debug.sh <cr>a
inoremap <A-r>r <Esc>:C ! <cr>a
inoremap <A-r>1 <Esc>:C r1<cr>a
inoremap <A-r>2 <Esc>:C r2<cr>a
inoremap <A-r>3 <Esc>:C r3<cr>a
inoremap <A-r>4 <Esc>:C r4<cr>a
inoremap <A-r>5 <Esc>:C r5<cr>a
inoremap <A-r>6 <Esc>:C r6<cr>a
inoremap <A-r>7 <Esc>:C r7<cr>a
inoremap <A-r>8 <Esc>:C r8<cr>a
inoremap <A-r>9 <Esc>:C r9<cr>a
inoremap <A-r>0 <Esc>:C r0<cr>a

nnoremap <A-r><A-r> :C ./debug.sh <cr>
nnoremap <A-r>r <Esc>:C ! <cr>a
nnoremap <A-r>r <Esc>:C !<cr>
nnoremap <A-r>1 <Esc>:C r1<cr>
nnoremap <A-r>2 <Esc>:C r2<cr>
nnoremap <A-r>3 <Esc>:C r3<cr>
nnoremap <A-r>4 <Esc>:C r4<cr>
nnoremap <A-r>5 <Esc>:C r5<cr>
nnoremap <A-r>6 <Esc>:C r6<cr>
nnoremap <A-r>7 <Esc>:C r7<cr>
nnoremap <A-r>8 <Esc>:C r8<cr>
nnoremap <A-r>9 <Esc>:C r9<cr>
nnoremap <A-r>0 <Esc>:C r0<cr>

" Tab navigate
nnoremap <A-,> gT
nnoremap <A-.> gt
inoremap <A-,> <ESC>gTi
inoremap <A-.> <ESC>gti
tnoremap <A-,> <C-\><C-n>gTi
tnoremap <A-.> <C-\><C-n>gti

imap <A-g> <Esc><Plug>(choosewin)
nmap <A-g> <Plug>(choosewin)
tmap <A-g> <C-\><C-n><Plug>(choosewin)

inoremap <A-m> <Esc>:Marks<cr>
nnoremap <A-m> :Marks<cr>

" Quickfix

inoremap <A-;> <Esc>:cp<cr>
nnoremap <A-;> :cp<cr>
tnoremap <A-;> <C-\><C-n><C-w>:cp<cr>
inoremap <A-'> <Esc>:cn<cr>
nnoremap <A-'> :cn<cr>
tnoremap <A-'> <C-\><C-n><C-w>:cn<cr>

" Location list
inoremap <A-[> <Esc>:lp<cr>
nnoremap <A-[> :lp<cr>
tnoremap <A-[> <C-\><C-n><C-w>:lp<cr>
inoremap <A-]> <Esc>:lne<cr>
nnoremap <A-]> :lne<cr>
tnoremap <A-]> <C-\><C-n><C-w>:lne<cr>

{% endif %}

function! ShowDoc()
  let l:my_filetype = &filetype
  echo l:my_filetype
  if l:my_filetype == 'scala'
    execute "EnDocBrowse"
  elseif l:my_filetype == 'java'
    execute "EnDocBrowse"
  else
    call LanguageClient_textDocument_hover()
  endif
endfunction

function! ShowDef()
  let l:my_filetype = &filetype
  echo l:my_filetype
  if l:my_filetype == 'scala'
    execute "EnDeclaration"
  elseif l:my_filetype == 'java'
    execute "EnDeclaration"
  else
    call LanguageClient_textDocument_definition()
  endif
endfunction

"imap <a-/> <Plug>(ncm2_manual_trigger)
"au TextChangedI * call ncm2#auto_trigger()
"let g:ncm2#complete_length=[[1,3],[7,4]]
