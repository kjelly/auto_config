" resize buffer
if bufwinnr(1)
  map = <C-W>+
  map - <C-W>-
  map } <C-W>>
  map { <C-W><
endif


" Use normal regex
" http://stevelosh.com/blog/2010/09/coming-home-to-vim
nnoremap / /\v
vnoremap / /\v

" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :call VisualSelection('f')<CR>
vnoremap <silent> # :call VisualSelection('b')<CR>

" Smart way to move between windows
nnoremap <C-j> <C-W>j
nnoremap <C-k> <C-W>k
nnoremap <C-h> <C-W>h
nnoremap <C-l> <C-W>l

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

inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"
inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"

" Find file/buffer
nnoremap <C-p> :call fzf#vim#files('', fzf#vim#with_preview('right'))<cr>

" Auto complete for all word
inoremap     <c-a>  <c-x><c-n>

" Insert mode completion
imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)

cnoremap <c-s> Explore scp://
cnoremap <c-h> <Left>
cnoremap <c-j> <Down>
cnoremap <c-k> <Up>
cnoremap <c-l> <Right>

{% if nvim %}tnoremap <C-q> <C-\><C-n>
{% endif %}
inoremap <C-q> <Esc>
nnoremap <C-q> i
vnoremap <C-q> <Esc>

{% if nvim %}tnoremap <C-]> <C-\><C-n>
{% endif %}
inoremap <C-]> <Esc>
nnoremap <C-]> i
vnoremap <C-]> <Esc>

nnoremap ; :

inoremap ;; <Esc>
{% if nvim %}tnoremap ;; <C-\><C-n> {% endif %}

nnoremap <Space> i_<Esc>r

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

" Delete one word
inoremap <C-e> <Esc>dwi

" Forware/backware word
inoremap <C-f> <Esc>w i
inoremap <C-b> <Esc>bi

" Paste text
inoremap <C-v> <Esc>pi

" Paste text from clipboard
vnoremap <c-c> "+y
vnoremap <Return> "+y

"Quickly move current line
nnoremap [e  :<c-u>execute 'move -1-'. v:count1<cr>
nnoremap ]e  :<c-u>execute 'move +'. v:count1<cr>

inoremap <C-d>     <Plug>(neosnippet_expand_or_jump)

let g:racer_cmd = "{{ HOME_PATH }}/.cargo/bin/racer"
let $RUST_SRC_PATH="{{ HOME_PATH }}/rust-src/src"

nnoremap zz za

map /  <Plug>(incsearch-forward)\v
map ?  <Plug>(incsearch-backward)\v
map g/ <Plug>(incsearch-stay)\v

nnoremap <F5> :C ./debug.sh<cr>
inoremap <F5> <Esc>:C ./debug.sh<cr>a

nnoremap <Tab> :Files<cr>
{% if nvim %} nnoremap <S-Tab> :call OpenBuffer()<cr>
{% else %} nnoremap <S-Tab> :Buffers<cr> {% endif %}

{% if nvim %}

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
tnoremap <A-a> <C-\><C-n>
inoremap <A-a> <Esc>
nnoremap <A-a> i
vnoremap <A-a> <Esc>
cnoremap <A-a> <Esc>

tnoremap å <C-\><C-n>
inoremap å <Esc>
nnoremap å i
vnoremap å <Esc>

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

tnoremap ˙ <C-\><C-n><C-w>h
tnoremap ∆ <C-\><C-n><C-w>j
tnoremap ˚ <C-\><C-n><C-w>k
tnoremap ¬ <C-\><C-n><C-w>l
nnoremap ˙ <C-w>h
nnoremap ∆ <C-w>j
nnoremap ˚ <C-w>k
nnoremap ¬ <C-w>l
inoremap ˙ <Esc><C-w>h
inoremap ∆ <Esc><C-w>j
inoremap ˚ <Esc><C-w>k
inoremap ¬ <Esc><C-w>l

" Find files/buffers
function! OpenBuffer()
  let buf=bufnr('%')
  bufdo if &buftype ==# 'terminal' | silent! execute 'file' b:term_title | endif
  exec 'b' buf
  execute "Buffers"
endfunction

inoremap <A-p> <Esc>:call fzf#vim#files('', fzf#vim#with_preview('right'))<cr>
nnoremap <A-p> :call fzf#vim#files('', fzf#vim#with_preview('right'))<cr>
tnoremap <A-p> <C-\><C-n>:call fzf#vim#files('', fzf#vim#with_preview('right'))<cr>a

inoremap <A-o> <Esc>:call OpenBuffer()<cr>
nnoremap <A-o> :call OpenBuffer()<cr>
tnoremap <A-o> <C-\><C-n>:call OpenBuffer()<cr>a

inoremap <A-i> <Esc>:Ag<cr>
nnoremap <A-i> :Ag<cr>
tnoremap <A-i> <C-\><C-n>:Ag<cr>a

inoremap <A-u> <Esc>:Buffers<cr>
nnoremap <A-u> :Buffers<cr>
tnoremap <A-u> <C-\><C-n>:Buffers<cr>a


" buufer switch
nnoremap <A-b> :b#<cr>
inoremap <A-b> <Esc>:b#<cr>
tnoremap <A-b> <C-\><C-n>:b#<cr>a

inoremap <A-;> <Esc><C-w>ja
nnoremap <A-;> a
tnoremap <A-;> <C-\><C-n><C-w>ka

" Save
inoremap <A-s> <Esc>:w<cr>a
nnoremap <A-s> :w<cr>

" Resize buffer
nnoremap <silent> <A-q>  :resize +1000<cr>
nnoremap <silent> <A-w>  <c-w><c-=>
nnoremap <silent> <A-e>  :resize -1000<cr>
nnoremap <silent> <A-r>  :vertical resize +1000<cr>
nnoremap <silent> <A-t>  :vertical resize -1000<cr>
inoremap <silent> <A-q>  <Esc>:resize +1000<cr>a
inoremap <silent> <A-w>  <Esc><c-w><c-=>i
inoremap <silent> <A-e>  <Esc>:resize -1000<cr>a
inoremap <silent> <A-r>  <Esc>:vertical resize +1000<cr>a
inoremap <silent> <A-t>  <Esc>:vertical resize -1000<cr>a
tnoremap <silent> <A-q>  <C-\><C-n>:resize +1000<cr>a
tnoremap <silent> <A-w>  <C-\><C-n><c-w><c-=>i
tnoremap <silent> <A-e>  <C-\><C-n>:resize -1000<cr>a
tnoremap <silent> <A-r>  <C-\><C-n>:vertical resize +1000<cr>a
tnoremap <silent> <A-t>  <C-\><C-n>:vertical resize -1000<cr>a

nnoremap <silent> œ :resize +1000<cr>
nnoremap <silent> ∑ <c-w><c-=>
nnoremap <silent> ´ :resize -1000<cr>
nnoremap <silent> ® :vertical resize +1000<cr>
nnoremap <silent> † :vertical resize -1000<cr>
inoremap <silent> œ <Esc>:resize +1000<cr>a
inoremap <silent> ∑ <Esc><c-w><c-=>i
inoremap <silent> ´ <Esc>:resize -1000<cr>a
inoremap <silent> ® <Esc>:vertical resize +1000<cr>a
inoremap <silent> † <Esc>:vertical resize -1000<cr>a
tnoremap <silent> œ <C-\><C-n>:resize +1000<cr>a
tnoremap <silent> ∑ <C-\><C-n><c-w><c-=>i
tnoremap <silent> ´ <C-\><C-n>:resize -1000<cr>a
tnoremap <silent> ® <C-\><C-n>:vertical resize +1000<cr>a
tnoremap <silent> † <C-\><C-n>:vertical resize -1000<cr>a

" Paste text
tnoremap <A-v> <C-\><C-n>pi
inoremap <A-v> <Esc>pi

inoremap <A-r>r <Esc>:C ! <cr>a

inoremap <A-r>1 <Esc>:C g1<cr>a
inoremap <A-r>2 <Esc>:C g2<cr>a
inoremap <A-r>3 <Esc>:C g3<cr>a
inoremap <A-r>4 <Esc>:C g4<cr>a
inoremap <A-r>5 <Esc>:C g5<cr>a
inoremap <A-r>6 <Esc>:C g6<cr>a
inoremap <A-r>7 <Esc>:C g7<cr>a
inoremap <A-r>8 <Esc>:C g8<cr>a
inoremap <A-r>9 <Esc>:C g9<cr>a
inoremap <A-r>0 <Esc>:C g0<cr>a

nnoremap <A-r>r <Esc>:C !<cr>
nnoremap <A-r>1 <Esc>:C g1<cr>
nnoremap <A-r>2 <Esc>:C g2<cr>
nnoremap <A-r>3 <Esc>:C g3<cr>
nnoremap <A-r>4 <Esc>:C g4<cr>
nnoremap <A-r>5 <Esc>:C g5<cr>
nnoremap <A-r>6 <Esc>:C g6<cr>
nnoremap <A-r>7 <Esc>:C g7<cr>
nnoremap <A-r>8 <Esc>:C g8<cr>
nnoremap <A-r>9 <Esc>:C g9<cr>
nnoremap <A-r>0 <Esc>:C g0<cr>


nnoremap <A-d> :DevDocsUnderCursor<cr>
nnoremap ∂ :DevDocsUnderCursor<cr>

" Tab navigate
nnoremap <A-,> gT
nnoremap <A-.> gt
inoremap <A-,> <ESC>gTi
inoremap <A-.> <ESC>gti
tnoremap <A-,> <C-\><C-n>gTi
tnoremap <A-.> <C-\><C-n>gti

nnoremap <silent> f :<C-u>call EasyMotion#overwin#w()<CR>

nnoremap <A-n> :NERDTreeTabsToggle<CR>
inoremap <A-n> <Esc>:NERDTreeTabsToggle<CR>
tnoremap <A-n> <C-\><C-n>:NERDTreeTabsToggle<CR>

inoremap <A-g> <C-o>:register<cr>
nnoremap <A-g> :register<cr>

inoremap <A-m> <Esc>:Marks<cr>
nnoremap <A-m> :Marks<cr>

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

nnoremap <silent> K :call ShowDoc()<CR>
nnoremap <silent> gd :call ShowDef()<CR>

inoremap <silent><expr> <A-/>
  \ pumvisible() ? "\<C-n>" :
  \ deoplete#mappings#manual_complete()
