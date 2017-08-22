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


" Sudo to write
cnoremap w!! w !sudo tee % >/dev/null


" When you press <leader>r you can search and replace the selected text
vnoremap <silent> <leader>r :call VisualSelection('replace')<CR>


" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :call VisualSelection('f')<CR>
vnoremap <silent> # :call VisualSelection('b')<CR>


" Fast saving
nnoremap <leader>sa :w!<cr>

" Disable highlight when <leader><cr> is pressed
nnoremap <silent> <leader><cr> :noh<cr>

" Close the current buffer
nnoremap <leader>bd :Bclose<cr>

" Close all the buffers
nnoremap <leader>ba :1,1000 bd!<cr>

" Switch CWD to the directory of the open buffer
nnoremap <leader>cd :cd %:p:h<cr>:pwd<cr>

" Smart way to move between windows
nnoremap <C-j> <C-W>j
nnoremap <C-k> <C-W>k
nnoremap <C-h> <C-W>h
nnoremap <C-l> <C-W>l

nnoremap <C-n> :NERDTreeTabsToggle<CR>

" Tab mappings
nnoremap <leader>tn :tabnew %<cr>
nnoremap <leader>to :tabonly<cr>
nnoremap <leader>tc :tabclose<cr>
nnoremap <leader>tm :tabmove
nnoremap <C-t> :tabnew %<CR>
inoremap <C-t> <Esc>:tabnew %<CR>
noremap H gT
noremap L gt


" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
nnoremap <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Spell checking
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Pressing ,ss will toggle and untoggle spell checking
nnoremap <leader>spel :setlocal spell!<cr>

" Shortcuts using <leader>
nnoremap <leader>spen ]s
nnoremap <leader>spep [s


" Grep
" B for current buffer
" For example, Lines for Lines in loaded buffers.
" BLines for Lines in the current buffer
nnoremap <leader>gro :Grep<cr>
nnoremap <leader>grr :Rgrep<cr>
nnoremap <leader>ge :Egrep<cr>
nnoremap <leader>gl :Lines<cr
nnoremap <leader>gbl :BLines<cr>
nnoremap <leader>gc :Commits<cr>
nnoremap <leader>gbc :BCommits<cr>
nnoremap <leader>ga :Ag<cr>

" When you press gv you vimgrep after the selected text
vnoremap <silent> gv :call VisualSelection('gv')<CR>

" Open vimgrep and put the cursor in the right position
nnoremap <leader>gv :vimgrep // **/* <left><left><left><left><left><left><left>

" Vimgreps in the current file
nnoremap <leader><space> :vimgrep // <Home><right><right><right><right><right><right><right><right><right>


" close buffer/window
nnoremap <leader>qq :Bclose<cr>:q<cr>
nnoremap <leader>qw :q<cr>
nnoremap <leader>qb :Bclose<cr>

" State
nnoremap <leader>,n :set nu!<cr>
nnoremap <leader>,w :set wrap!<cr>
nnoremap <leader>,p :setlocal paste!<cr>
nnoremap <leader>,m :call ToggleMouse()<cr>
nnoremap <leader>,s :call ToggleStatusLine()<cr>

" Find file in NERDTree
nnoremap <leader>ff :NERDTreeMirrorOpen<cr>:NERDTreeTabsFind<cr>

" Find  line in the current buffer
nnoremap <leader>fb :BLine
" Find  lines in loaded buffers
nnoremap <leader>fl :Line

" format code
noremap <leader>fc :Autoformat<CR>

" Command
nnoremap <leader>e :Commands<cr>
nnoremap <C-e> :Commands<cr>

" Tag list
nnoremap <C-s> :Tagbar<cr>

inoremap <C-s> <Esc>:w<cr>a

" Bookmarks keybinding
"nnoremap <Leader>bt <Plug>BookmarkToggle
"nnoremap <Leader>bi <Plug>BookmarkAnnotate
"nnoremap <Leader>ba <Plug>BookmarkShowAll
"nnoremap <Leader>bj <Plug>BookmarkNext
"nnoremap <Leader>bk <Plug>BookmarkPrev
"nnoremap <Leader>bc <Plug>BookmarkClear
"nnoremap <Leader>bx <Plug>BookmarkClearAll
"nnoremap <Leader>bk <Plug>BookmarkMoveUp
"nnoremap <Leader>bj <Plug>BookmarkMoveDown

" Use down/up for <C-n>/<C-p>
inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"
inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"

nnoremap <C-u> :UndotreeToggle<cr>

" Find file/buffer
nnoremap <C-p> :FZF<cr>
nnoremap <c-o> :Buffers<cr>

"nnoremap <leader>w :W3mTab google

" Resize buffer
nnoremap sa  :resize +1000<cr>
nnoremap si  :resize -1000<cr>
nnoremap sm  <c-w><c-=>

" Find window
nnoremap <a-/>  :Windows<cr>
inoremap     <a-/>  :Windows<cr>

" Auto complete for all word
inoremap     <c-a>  <c-x><c-n>

" Easymotion
nmap S <Plug>(easymotion-s)
nmap f <Plug>(easymotion-overwin-w)
map <Leader><leader>h <Plug>(easymotion-linebackward)
map <Leader><Leader>j <Plug>(easymotion-j)
map <Leader><Leader>k <Plug>(easymotion-k)
map <Leader><leader>l <Plug>(easymotion-lineforward)

{% if nvim %}

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

noremap <Esc>h <Nop>
noremap <Esc>l <Nop>

" Delete one word
inoremap <C-e> <Esc>dwi

" Forware/backware word
inoremap <C-f> <Esc>w i
inoremap <C-b> <Esc>bi

" Paste text
inoremap <C-v> <Esc>pi

" insert new after the line
inoremap <C-o> <Esc>:Buffers<cr>

" Paste text from clipboard
vnoremap <c-c> "+y
vnoremap <Return> "+y

"Quickly move current line
nnoremap [e  :<c-u>execute 'move -1-'. v:count1<cr>
nnoremap ]e  :<c-u>execute 'move +'. v:count1<cr>

inoremap <C-d>     <Plug>(neosnippet_expand_or_jump)

" keybinding about lang
au FileType go nnoremap <leader>le :GoRun<cr>
au FileType go nnoremap <leader>lb :GoBuild<cr>
au FileType go nnoremap <leader>lt :GoTest<cr>
au FileType go nnoremap <leader>lc <Plug>(go-coverage)
au FileType go nnoremap <leader>lde :<C-u>call go#def#Jump('')<CR>
au FileType go nnoremap <leader>lds :<C-u>call go#def#Jump("split")<CR>
au FileType go nnoremap <leader>ldv :<C-u>call go#def#Jump("vsplit")<CR>
au FileType go nnoremap <leader>ldt :<C-u>call go#def#Jump("tab")<CR>
au FileType go nnoremap <leader>lk :GoDoc<cr>
au FileType go nnoremap <leader>ls :GoImplements<cr>
au FileType go nnoremap <leader>li :GoInfo<cr>
au FileType go nnoremap <leader>lrn :GoRename<cr>
au FileType go nnoremap <leader>lrf :GoReferrers<cr>
au FileType go nnoremap <leader>lce :GoCallees<cr>
au FileType go nnoremap <leader>lcr :GoCallers<cr>

let g:jedi#goto_command = "<leader>lde"
let g:jedi#goto_assignments_command = "<leader>lga"
let g:jedi#goto_definitions_command = "<leader>lde"
let g:jedi#documentation_command = "<leader>k"
let g:jedi#usages_command = "<leader>li"
let g:jedi#completions_command = "<C-Space>"
let g:jedi#rename_command = "<leader>lrn"

let g:racer_cmd = "{{ HOME_PATH }}/.cargo/bin/racer"
let $RUST_SRC_PATH="{{ HOME_PATH }}/rust-src/src"

" Gina
nnoremap <leader>vs :Gina status<cr>
nnoremap <leader>vpull :Gina pull<cr>
nnoremap <leader>vpush :Gina push<cr>
nnoremap <leader>vf :Gina fetch<cr>
nnoremap <leader>vd :Gina diff<cr>
nnoremap <leader>vl :Gina log<cr>
nnoremap <leader>vc :Gina commit<cr>
nnoremap <leader>va :Gina add
nnoremap <leader>vt :Gina tag<cr>
nnoremap <leader>vb :Gina branch<cr>

{% if nvim %}

" Disable mouse
set mouse=""

" open new terminal in new tab/buffer.
map <leader>tt :tabnew %<cr>:terminal<cr>
map <leader>tb :split<cr><c-w>j:terminal<cr>

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

tnoremap å <C-\><C-n>
inoremap å <Esc>
nnoremap å i
vnoremap å <Esc>

tnoremap <C-q> <C-\><C-n>
inoremap <C-q> <Esc>
nnoremap <C-q> i
vnoremap <C-q> <Esc>

tnoremap <C-]> <C-\><C-n>
inoremap <C-]> <Esc>
nnoremap <C-]> i
vnoremap <C-]> <Esc>

" Buffer navigation
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
nnoremap <A-o> :Buffers<cr>
tnoremap <A-o> <C-\><C-n>Buffers<cr>a

" Quickfix
nnoremap <A-p> :lprevious<cr>
inoremap <A-p> <Esc>:lprevious<cr>
nnoremap <A-n> :lnext<cr>
inoremap <A-n> <Esc>:lnextnext<cr>
nnoremap <A-s> :lopen<cr>
inoremap <A-s> <Esc>:lopen<cr>

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

inoremap <A-o> <Esc>:Buffers<cr>

nnoremap <A-d> :DevDocsUnderCursor<cr>
nnoremap ∂ :DevDocsUnderCursor<cr>

" Tab navigate
nnoremap <A-,> gT
nnoremap <A-.> gt
inoremap <A-,> <ESC>gTi
inoremap <A-.> <ESC>gti
tnoremap <A-,> <C-\><C-n>gTi
tnoremap <A-.> <C-\><C-n>gti

nnoremap <A-f> :Ag<cr>
nnoremap ƒ :Ag<cr>
inoremap <Esc><A-f> :Ag<cr>
inoremap ƒ :Ag<cr>
{% endif %}

nnoremap <silent> K :call LanguageClient_textDocument_hover()<CR>
nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>

nnoremap <silent> <leader>lsf :call LanguageClient_textDocument_documentSymbol()<CR>
nnoremap <silent> <leader>lsw :call LanguageClient_workspace_symbol()<CR>
nnoremap <silent> <leader>lrf :call LanguageClient_textDocument_references()<CR>
nnoremap <silent> <leader>lrn :call LanguageClient_textDocument_rename()<CR>
nnoremap <silent> <leader>lf :call LanguageClient_textDocument_formatting()<CR>
