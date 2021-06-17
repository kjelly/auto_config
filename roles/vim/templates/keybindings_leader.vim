" Grep
" B for current buffer
" For example, Lines for Lines in loaded buffers.
" BLines for Lines in the current buffer
nnoremap <leader><leader> :

nnoremap <silent> <leader>zl :Lines<cr>
nnoremap <silent> <leader>zbl :BLines<cr>
nnoremap <silent> <leader>zc :Commits<cr>
nnoremap <silent> <leader>zbc :BCommits<cr>
nnoremap <silent> <leader>zhf :History<cr>
nnoremap <silent> <leader>zhc :History:<cr>
nnoremap <silent> <leader>zhs :History/<cr>
nnoremap <silent> <leader>zm :Marks<cr>
nnoremap <silent> <leader>za :Ag<cr>
nnoremap <silent> <leader>zf :Files<cr>
nnoremap <silent> <leader>zp :Files<cr>
nnoremap <silent> <leader>zo :Buffers<cr>
nnoremap <silent> <leader>zg :GitFiles<cr>
nnoremap <silent> <leader>zr :Rg<cr>

nnoremap <silent> <leader>gs :Gstatus<CR>
nnoremap <silent> <leader>gd :Gdiff<CR>
nnoremap <silent> <leader>gc :Git commit<CR>
nnoremap <silent> <leader>gb :Git blame<CR>
nnoremap <silent> <leader>gl :Git log<CR>
nnoremap <silent> <leader>gp :Git push<CR>
nnoremap <silent> <leader>gr :Gread<CR>
nnoremap <silent> <leader>gw :Gwrite<CR>
nnoremap <silent> <leader>ge :Gedit<CR>
nnoremap <leader>gi :call RunShellAndShow('git add -p %:p')<cr>
nnoremap <silent> <leader>gg :SignifyToggle<CR>
nnoremap <silent> <leader>gu :Git pull --rebase<CR>
nnoremap <silent> <leader>ga :Agit<CR>
nnoremap <silent> <leader>gdi :Git diff<CR>
nnoremap <silent> <leader>gdl :Git diff @~..@<CR>

nnoremap <silent> <leader>id :put =strftime('%Y-%m-%d')<cr>
nnoremap <silent> <leader>it :put =strftime('%H:%M:%S')<cr>
nnoremap <silent> <leader>ic :colorscheme<cr>

" Disable highlight
nnoremap <silent> <leader>sh :noh<cr>

" Switch CWD to the directory of the open buffer
nnoremap <leader>cd :Pushd %:p:h<cr>:pwd<cr>
nnoremap <leader>cc :call RunShellAndShow('')<left><left>
"nnoremap <leader>co  " for rnadom colorscheme

nnoremap <leader>fx :Explore<space>
nnoremap <leader>fr :Explore scp://
nnoremap <silent> <leader>fb :Rexplore<CR>
nnoremap <silent> <leader>fv :Vaffle<CR>
nnoremap <silent> <leader>fs :w<CR>
nnoremap <silent> <leader>fi :call FindFileInTree()<CR>
nnoremap <leader>fe :edit <c-r>=expand("%:p:h")<cr>/

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

nmap <Leader>tr <Plug>(coc-translator-p)


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

" State / Switch
function ToggleIndentLine()
  if exists(":IndentLinesToggle")
    execute "IndentLinesToggle"
  elseif exists(":IndentBlanklineToggle")
    execute ":IndentBlanklineToggle"
  endif
endfunction

nnoremap <silent> <leader>sn :set nu!<cr>
nnoremap <silent> <leader>sw :set wrap!<cr>
nnoremap <silent> <leader>sp :set paste!<cr>
nnoremap <silent> <leader>sm :call ToggleMouse()<cr>
nnoremap <silent> <leader>ss :call ToggleStatusLine()<cr>
nnoremap <silent> <leader>sl :call ToggleIndentLine()<cr>
nnoremap <silent> <leader>si :source Session.vim<cr>
nnoremap <silent> <leader>se :mksession!<cr>
nnoremap <silent> <leader>sc :call ToggleForCopy()<cr>
nnoremap <silent> <leader>st :Switch<cr>
nnoremap <silent> <leader>sk :DisableTmuxKey<cr>

" Bookmarks keybinding
nnoremap <silent> mm :BookmarkToggle<cr>
nnoremap <silent> <Leader>bb :BookmarkToggle<cr>
nnoremap <silent> <Leader>bt :BookmarkToggle<cr>
nnoremap <silent> <Leader>bi :BookmarkAnnotate<cr>
nnoremap <silent> <Leader>bl :BookmarkShowAll<cr>
nnoremap <silent> <Leader>bj :BookmarkNext<cr>
nnoremap <silent> <Leader>bk :BookmarkPrev<cr>
nnoremap <silent> <Leader>bc :BookmarkClear<cr>
nnoremap <silent> <Leader>bx :BookmarkClearAll<cr>

nnoremap <silent> <leader>bs :b#<cr>
nnoremap <silent> <leader>br :redraw<cr>

"nnoremap <leader>w :W3mTab google

" Easymotion
nmap <leader>ms <Plug>(easymotion-s)
nmap <leader>mf <Plug>(easymotion-overwin-w)
nmap <Leader>mh <Plug>(easymotion-linebackward)
nmap <Leader>mj <Plug>(easymotion-j)
nmap <Leader>mk <Plug>(easymotion-k)
nmap <Leader>ml <Plug>(easymotion-lineforward)

nnoremap <silent> <leader>mm :Marks<cr>
nnoremap <silent> <leader>mn ]`
nnoremap <silent> <leader>mp [`
nnoremap <silent> <leader>mc :delmarks!<cr>
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
nnoremap <leader>vi :call RunShellAndShow('git add -p %:p')<cr>


autocmd FileType vimwiki nmap <space><space> <Plug>VimwikiToggleListItem

nnoremap <silent> <leader>wf :call fzf#vim#ag('', {'dir': '~/Dropbox/vimwiki/', 'down': '40%'})<cr>
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

nnoremap <silent> <leader>ed :e <c-r>=expand("%:p:h")<cr>/<cr>
nnoremap <silent> <leader>eu :UndotreeToggle<cr>
nnoremap <silent> <leader>esi :e $MYVIMRC<cr>
nnoremap <silent> <leader>esl :e ~/.vim_custom.vim<cr>
nnoremap <silent> <leader>esc :e ~/.config/nvim/config.lua<cr>
nnoremap <silent> <leader>er :registers<cr>
nnoremap <leader>ef :set filetype=
nnoremap <leader>ea :filetype detect<cr>
nnoremap <silent> <leader>eg :Grepper<cr>
nnoremap <silent> <leader>ej ::%!jq '.'<cr>
nnoremap <leader>ee :terminal<space>
cnoremap <silent> <c-e> <Esc>:History:<cr>

nnoremap <silent> <leader>en :echo getcwd()<cr>
nnoremap <silent> <leader>em :Pushd <c-r>=expand("%:p:h")<cr><cr>
nnoremap <silent> <leader>ecr :let @a=@%<cr>
nnoremap <silent> <leader>ecn :let @a=expand("%:t")<cr>
nnoremap <silent> <leader>ecf :let @a=expand("%:p")<cr>
nnoremap <silent> <leader>ecd :let @a=expand("%:p:h")<cr>

nnoremap <silent> <leader>pp :put<cr>
nnoremap <silent> <leader>pr :put<cr>G$a<cr>
nnoremap <leader>pu :PlugUpdate<cr>
nnoremap <leader>pi :PlugInstall<cr>

" Run/Test
nnoremap <silent> <leader>rt :TestNearest<cr>
nnoremap <silent> <leader>rs :TestSuite<cr>
nnoremap <silent> <leader>rf :TestFile<cr>
nnoremap <silent> <leader>rr :History:<cr>
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
nnoremap <silent> <leader>tt :tabnew %<cr>:terminal<cr>
nnoremap <silent> <leader>td :OpenDefaultTerm<cr>
nnoremap <silent> <leader>tb :split<cr><c-w>j:terminal<cr>
nnoremap <silent> <leader>tv :vsplit<cr><c-w>l:terminal<cr>


{% endif %}

" Remap for format selected region
vmap <leader>f  <Plug>(coc-format-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
nnoremap <leader>aj :AnyJump<CR>
nnoremap <leader>ab :AnyJumpBack<CR>
nnoremap <leader>al :AnyJumpLastResults<CR>

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
nnoremap <silent> <leader>lld :<C-u>CocList diagnostics<cr>
nnoremap <silent> <leader>lle :<C-u>CocList extensions<cr>
nnoremap <silent> <leader>llc :<C-u>CocList commands<cr>
nnoremap <silent> <leader>llo :<C-u>CocList outline<cr>
nnoremap <silent> <leader>lls :<C-u>CocList outline<cr>
nnoremap <leader>lse :CocSearch<space>
nnoremap <silent> <leader>lsw :ISwap<cr>
nmap <silent> <leader>lrf <Plug>(coc-references)
nmap <silent> <leader>lrn <Plug>(coc-rename)
nnoremap <silent> <leader>lf :call CocAction('format')<cr>
nmap <silent> <leader>li <Plug>(coc-implementation)
nnoremap <silent> <leader>la :CocAction<cr>
nnoremap <silent> <leader>lll :CocList<cr>
nmap <silent> <leader>ltd <Plug>(coc-type-definition)
nnoremap <silent> <leader>ltf :TestFile<cr>
nnoremap <silent> <leader>ltn :TestNearest<cr>
nnoremap <silent> <leader>lts :TestSuite<cr>
nnoremap <silent> <leader>ltv :TestVisit<cr>
nnoremap <leader>lc :FloatermNew curl 'cht.sh/<c-r>=&filetype<cr>/'<left>
nnoremap <leader>ldg :C ddgr <c-r>=&filetype<cr><space>
nnoremap <leader>lg :C w w3m, w3m -no-cookie 'https://www.startpage.com/search?q=<c-r>=&filetype<cr> '<left>
nnoremap <silent> <leader>lb :C brow<cr>

nnoremap <silent> <leader>lel :LeetCodeList<cr>
nnoremap <silent> <leader>les :LeetCodeSubmit<cr>
nnoremap <silent> <leader>let :LeetCodeTest<cr>

nnoremap <silent> <localleader>dt :lua require'dap'.toggle_breakpoint()<cr>
nnoremap <silent> <localleader>dc :lua require'dap'.continue()<cr>
nnoremap <silent> <localleader>di :lua require'dap'.step_into()<cr>
nnoremap <silent> <localleader>do :lua require'dap'.step_over()<cr>
nnoremap <silent> <localleader>dr :lua require'dap'.repl.open()<cr>

nnoremap <silent> <localleader>a :Ag<cr>
nnoremap <silent> <localleader>b :b#<cr>
nnoremap <silent> <localleader>g :ChooseWin<cr>
nnoremap <silent> <localleader>t :tabnew %<cr>
nnoremap <silent> <localleader>h :wincmd h<cr>
nnoremap <silent> <localleader>j :wincmd j<cr>
nnoremap <silent> <localleader>k :wincmd k<cr>
nnoremap <silent> <localleader>l :wincmd l<cr>
nnoremap <silent> <localleader>o :Buffers<cr>
nnoremap <silent> <localleader>q :q!<cr>
nnoremap <silent> <localleader>p :Files<cr>
nnoremap <silent> <localleader>t :tabnew %<cr>
nnoremap <localleader>rr :lua MyRun({''})<left><left><left>
nnoremap <localleader>e :call RunShellAndShow('')<left><left>
