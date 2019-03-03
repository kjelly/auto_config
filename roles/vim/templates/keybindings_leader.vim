" Grep
" B for current buffer
" For example, Lines for Lines in loaded buffers.
" BLines for Lines in the current buffer
nnoremap <leader>zl :Lines<cr>
nnoremap <leader>zbl :BLines<cr>
nnoremap <leader>zc :Commits<cr>
nnoremap <leader>zbc :BCommits<cr>
nnoremap <leader>zhf :History<cr>
nnoremap <leader>zhc :History:<cr>
nnoremap <leader>zhs :History/<cr>
nnoremap <leader>zm :Marks<cr>
nnoremap <leader>za :Ag<cr>
nnoremap <leader>zf :Files<cr>
nnoremap <leader>zp :Files<cr>
nnoremap <leader>zo :Buffers<cr>
nnoremap <leader>zg :GitFiles<cr>
nnoremap <leader>zr :Rg<cr>

nnoremap <silent> <leader>gs :Gstatus<CR>
nnoremap <silent> <leader>gd :Gdiff<CR>
nnoremap <silent> <leader>gc :Gcommit<CR>
nnoremap <silent> <leader>gb :Gblame<CR>
nnoremap <silent> <leader>gl :Glog<CR>
nnoremap <silent> <leader>gp :Git push<CR>
nnoremap <silent> <leader>gr :Gread<CR>
nnoremap <silent> <leader>gw :Gwrite<CR>
nnoremap <silent> <leader>ge :Gedit<CR>
nnoremap <silent> <leader>gi :Git add -p %<CR>
nnoremap <silent> <leader>gg :SignifyToggle<CR>
nnoremap <silent> <leader>gu :Gpull --rebase<CR>
nnoremap <silent> <leader>ga :Agit<CR>

" When you press <leader>r you can search and replace the selected text
vnoremap <silent> <leader>r :call VisualSelection('replace')<CR>


" Visual mode pressing * or # searches for the current selection
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :call VisualSelection('f')<CR>
vnoremap <silent> # :call VisualSelection('b')<CR>

" Disable highlight
nnoremap <silent> <leader>g<cr> :noh<cr>

" Switch CWD to the directory of the open buffer
nnoremap <leader>cd :Pushd %:p:h<cr>:pwd<cr>

nnoremap <silent> <leader>fx :Explore<space>
nnoremap <silent> <leader>fr :Explore scp://
nnoremap <silent> <leader>fb :Rexplore<CR>
nnoremap <silent> <leader>ft :NERDTreeToggle<CR>
nnoremap <silent> <leader>fv :Vaffle<CR>
nnoremap <silent> <leader>fs :w<CR>

" Tab mappings
nnoremap <leader>to :tabonly<cr>
nnoremap <leader>tc :tabclose<cr>
nnoremap <leader>tm :tabmove
nnoremap <leader>tp :tcd <c-r>=expand("%:p:h")<cr><cr>

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
nnoremap <leader>te :tabedit %<cr>

" Open vimgrep and put the cursor in the right position
"nnoremap <leader>gv :vimgrep // **/* <left><left><left><left><left><left><left>

" Vimgreps in the current file
"nnoremap <leader><space> :vimgrep // <Home><right><right><right><right><right><right><right><right><right>

" close buffer/window
nnoremap <leader>qq :Bclose<cr>:q<cr>
nnoremap <leader>qw :q<cr>
nnoremap <leader>qb :Bclose<cr>

" State
nnoremap <leader>sn :set nu!<cr>
nnoremap <leader>sw :set wrap!<cr>
nnoremap <leader>sp :set paste!<cr>
nnoremap <leader>sm :call ToggleMouse()<cr>
nnoremap <leader>ss :call ToggleStatusLine()<cr>
nnoremap <leader>sl :IndentLinesToggle<cr>
nnoremap <leader>si :source Session.vim<cr>
nnoremap <leader>se :mksession!<cr>
nnoremap <leader>sc :ColorToggle<cr>

" Find file in NERDTree
nnoremap <leader>ff :NERDTreeMirrorOpen<cr>:NERDTreeTabsFind<cr>
nnoremap <leader>fe :edit <c-r>=expand("%:p:h")<cr>/
nnoremap <leader>ed :Explore <c-r>=expand("%:p:h")<cr><cr>
nnoremap <leader>fi :NERDTreeMirrorOpen<cr>:NERDTreeTabsFind<cr>

" Bookmarks keybinding
nnoremap mm :BookmarkToggle<cr>
nnoremap <Leader>bb :BookmarkToggle<cr>
nnoremap <Leader>bt :BookmarkToggle<cr>
nnoremap <Leader>bi :BookmarkAnnotate<cr>
nnoremap <Leader>bl :BookmarkShowAll<cr>
nnoremap <Leader>bj :BookmarkNext<cr>
nnoremap <Leader>bk :BookmarkPrev<cr>
nnoremap <Leader>bc :BookmarkClear<cr>
nnoremap <Leader>bx :BookmarkClearAll<cr>

nnoremap <leader>bs :b#<cr>
nnoremap <leader>br :redraw<cr>

"nnoremap <leader>w :W3mTab google

" Easymotion
nmap <leader>ms <Plug>(easymotion-s)
nmap <leader>mf <Plug>(easymotion-overwin-w)
nmap <Leader>mh <Plug>(easymotion-linebackward)
nmap <Leader>mj <Plug>(easymotion-j)
nmap <Leader>mk <Plug>(easymotion-k)
nmap <Leader>ml <Plug>(easymotion-lineforward)

nnoremap <leader>mm :Marks<cr>
nnoremap <leader>mn ]`
nnoremap <leader>mp [`
nnoremap <leader>mc :delmarks!<cr>
nnoremap <leader>mg `.
" Gina
"nnoremap <leader>vs :Gina status<cr>
"nnoremap <leader>vpl :Gina pull<cr>
"nnoremap <leader>vph :Gina push<cr>
"nnoremap <leader>vf :Gina fetch<cr>
"nnoremap <leader>vd :Gina diff<cr>
"nnoremap <leader>vl :Gina log<cr>
"nnoremap <leader>vc :Gina commit<cr>
"nnoremap <leader>va :Gina add<space>
"nnoremap <leader>vt :Gina tag<cr>
"nnoremap <leader>vb :Gina branch<cr>
"nnoremap <leader>vv :Gina<space>

autocmd FileType vimwiki nmap <leader><space> <Plug>VimwikiToggleListItem

nnoremap <leader>wf :call fzf#vim#ag('', {'dir': '~/Dropbox/vimwiki/', 'down': '40%'})<cr>
nnoremap <leader>wr :WinResizerStartResize<cr>
nnoremap <leader>wm :WinResizerStartMove<cr>
nnoremap <leader>wf :WinResizerStartFocus<cr>

nnoremap <leader>wh :wincmd h<cr>
nnoremap <leader>wj :wincmd j<cr>
nnoremap <leader>wk :wincmd k<cr>
nnoremap <leader>wl :wincmd l<cr>

nnoremap <leader>eu :UndotreeToggle<cr>
nnoremap <leader>es :e $MYVIMRC<cr>
nnoremap <leader>er :registers<cr>
nnoremap <leader>ef :set filetype=
nnoremap <leader>eg :Grepper<cr>
nnoremap <leader>el :e ~/.vim_custom.vim<cr>
nnoremap <leader>ej ::%!jq '.'<cr>
nnoremap <leader>ee :terminal<space>
cnoremap <c-e> <Esc>:History:<cr>

nnoremap <leader>en :echo getcwd()<cr>
nnoremap <leader>em :Pushd <c-r>=expand("%:p:h")<cr><cr>
nnoremap <leader>ecr :let @a=@%<cr>
nnoremap <leader>ecn :let @a=expand("%:t")<cr>
nnoremap <leader>ecf :let @a=expand("%:p")<cr>
nnoremap <leader>ecd :let @a=expand("%:p:h")<cr>

nnoremap <leader>pp :put<cr>
nnoremap <leader>pr :put<cr>G$a<cr>

" Run/Test
nnoremap <leader>rt :TestNearest<cr>
nnoremap <leader>rs :TestSuite<cr>
nnoremap <leader>rf :TestFile<cr>
nnoremap <leader>rr :History:<cr>
nnoremap <leader>rd :C ./debug.sh<cr>

nnoremap <leader>o0 :set foldlevel=0<CR>
nnoremap <leader>o1 :set foldlevel=1<CR>
nnoremap <leader>o2 :set foldlevel=2<CR>
nnoremap <leader>o3 :set foldlevel=3<CR>
nnoremap <leader>o4 :set foldlevel=4<CR>
nnoremap <leader>o5 :set foldlevel=5<CR>
nnoremap <leader>o6 :set foldlevel=6<CR>
nnoremap <leader>o7 :set foldlevel=7<CR>
nnoremap <leader>o8 :set foldlevel=8<CR>
nnoremap <leader>o9 :set foldlevel=9<CR>
nnoremap <leader>oo zR<CR>
nnoremap <leader>oc zM<CR>


{% if nvim %}
function! DefaultTerminal()
  let buf=bufnr('%')
  terminal
  C n w3m
  terminal
  :C n how2
  execute 'b' buf
endfunction
command! -register OpenDefaultTerm call DefaultTerminal()

" open new terminal in new tab/buffer.
nnoremap <leader>tt :tabnew %<cr>:terminal<cr>
nnoremap <leader>td :OpenDefaultTerm<cr>
nnoremap <leader>tb :split<cr><c-w>j:terminal<cr>
nnoremap <leader>tv :vsplit<cr><c-w>l:terminal<cr>


{% endif %}

" Remap for format selected region
vmap <leader>f  <Plug>(coc-format-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf  <Plug>(coc-fix-current)

command! -nargs=0 Format :call CocAction('format')
command! -nargs=? Fold :call     CocAction('fold', <f-args>)
function! s:show_documentation()
  if &filetype == 'vim'
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction
nmap <silent> gd <Plug>(coc-definition)
nnoremap <silent> K :call <SID>show_documentation()<CR>
nnoremap <silent> <leader>ldd :<C-u>CocList diagnostics<cr>
nnoremap <silent> <leader>lde :<C-u>CocList extensions<cr>
nnoremap <silent> <leader>ldc :<C-u>CocList commands<cr>
nnoremap <silent> <leader>ldo :<C-u>CocList outline<cr>
nnoremap <silent> <leader>lsf :<C-u>CocList -I symbols<cr>
nnoremap <silent> <leader>lrf <Plug>(coc-references)
nnoremap <silent> <leader>lrn <Plug>(coc-rename)
nnoremap <silent> <leader>lf :call CocAction('format')
nnoremap <silent> <leader>li <Plug>(coc-implementation)
nnoremap <silent> <leader>la :call LanguageClient_contextMenu()<CR>
nnoremap <silent> <leader>ltd <Plug>(coc-type-definition)
nnoremap <silent> <leader>ltf :TestFile<cr>
nnoremap <silent> <leader>ltn :TestNearest<cr>
nnoremap <silent> <leader>lts :TestSuite<cr>
nnoremap <silent> <leader>ltv :TestVisit<cr>
nnoremap <leader>lc :C curl 'cht.sh/<c-r>=&filetype<cr>/'<left>
nnoremap <leader>ldg :C ddgr <c-r>=&filetype<cr><space>
nnoremap <leader>lg :C w w3m, w3m -no-cookie 'https://www.google.com/search?q=<c-r>=&filetype<cr> '<left>
nnoremap <leader>ldd :C k dict, dict.sh ''<left>
nnoremap <leader>lh :C k how2, how2 -l <c-r>=&filetype<cr><space>
nnoremap <leader>lb :C brow<cr>

nnoremap <localleader>o :Buffers<cr>
nnoremap <localleader>p :Files<cr>
nnoremap <localleader>b :b#<cr>
nnoremap <localleader>q :q!<cr>
nnoremap <localleader>s :w<cr>
nnoremap <localleader>a :Ag<cr>
nnoremap <localleader>c :C<space>
nnoremap <localleader>g :ChooseWin<cr>
nnoremap <localleader>n :NERDTreeToggle<cr>
nnoremap <localleader>h :wincmd h<cr>
nnoremap <localleader>j :wincmd j<cr>
nnoremap <localleader>k :wincmd k<cr>
nnoremap <localleader>l :wincmd l<cr>


