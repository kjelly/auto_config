" Grep
" B for current buffer
" For example, Lines for Lines in loaded buffers.
" BLines for Lines in the current buffer
nnoremap <leader>zl :Lines<cr>
nnoremap <leader>zbl :BLines<cr>
nnoremap <leader>zc :Commits<cr>
nnoremap <leader>zbc :BCommits<cr>
nnoremap <leader>zh :History<cr>
nnoremap <leader>zm :Marks<cr>
nnoremap <leader>za :Ag<cr>
nnoremap <leader>zf :Files<cr>
nnoremap <leader>zp :Files<cr>
nnoremap <leader>zo :Buffers<cr>
nnoremap <leader>zg :GitFiles<cr>

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
nnoremap <leader>cd :cd %:p:h<cr>:pwd<cr>

nnoremap <silent> <leader>fx :Explore<space>
nnoremap <silent> <leader>fr :Explore scp://
nnoremap <silent> <leader>fb :Rexplore<CR>
nnoremap <silent> <leader>ft :NERDTreeToggle<CR>

" Tab mappings
nnoremap <leader>tn :tabnew %<cr>
nnoremap <leader>to :tabonly<cr>
nnoremap <leader>tc :tabclose<cr>
nnoremap <leader>tm :tabmove

" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
nnoremap <leader>te :terminal<cr>

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
nnoremap <leader>sp :setlocal paste!<cr>
nnoremap <leader>sm :call ToggleMouse()<cr>
nnoremap <leader>ss :call ToggleStatusLine()<cr>

" Find file in NERDTree
nnoremap <leader>ff :NERDTreeMirrorOpen<cr>:NERDTreeTabsFind<cr>
nnoremap <leader>fe :edit <c-r>=expand("%:p:h")<cr>/
nnoremap <leader>ed :Explore <c-r>=expand("%:p:h")<cr><cr>
nnoremap <leader>fi :NERDTreeMirrorOpen<cr>:NERDTreeTabsFind<cr>

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


"nnoremap <leader>w :W3mTab google

" Easymotion
nmap <leader>ms <Plug>(easymotion-s)
nmap <leader>mf <Plug>(easymotion-overwin-w)
nmap <Leader>mh <Plug>(easymotion-linebackward)
nmap <Leader>mj <Plug>(easymotion-j)
nmap <Leader>mk <Plug>(easymotion-k)
nmap <Leader>ml <Plug>(easymotion-lineforward)

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

nnoremap <leader>eu :UndotreeToggle<cr>
nnoremap <leader>es :e $MYVIMRC<cr>
nnoremap <leader>er :registers<cr>


{% if nvim %}

" open new terminal in new tab/buffer.
map <leader>tt :tabnew %<cr>:terminal<cr>
map <leader>tb :split<cr><c-w>j:terminal<cr>

nnoremap <leader>bp :b#<cr>

{% endif %}

nnoremap <silent> <leader>lsf :call LanguageClient_textDocument_documentSymbol()<CR>
nnoremap <silent> <leader>lsw :call LanguageClient_workspace_symbol()<CR>
nnoremap <silent> <leader>lrf :call LanguageClient_textDocument_references()<CR>
nnoremap <silent> <leader>lrn :call LanguageClient_textDocument_rename()<CR>
nnoremap <silent> <leader>lf :call LanguageClient_textDocument_formatting()<CR>
