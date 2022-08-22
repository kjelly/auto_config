nnoremap <silent> . <cmd>JABSOpen<cr>

nnoremap D <cmd>lua vim.diagnostic.open_float()<cr>

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
nnoremap <silent> <leader>zo :JABSOpen<cr>
nnoremap <silent> <leader>zg :GitFiles<cr>
nnoremap <silent> <leader>zr :Rg<cr>

xmap ga <Plug>(EasyAlign)
nnoremap <silent> <leader>gs :Gstatus<CR>
nnoremap <silent> <leader>gc :Git commit<CR>
nnoremap <silent> <leader>gb :Git blame<CR>
nnoremap <silent> <leader>glo :Git log<CR>
nnoremap <silent> <leader>gp :Git push<CR>
nnoremap <silent> <leader>gr :Gread<CR>
nnoremap <silent> <leader>gw :Gwrite<CR>
nnoremap <silent> <leader>ge :Gedit<CR>
nnoremap <silent> <leader>gi :Git add -p %<CR>
nnoremap <silent> <leader>gg :SignifyToggle<CR>
nnoremap <silent> <leader>gu :Git pull --rebase<CR>
nnoremap <silent> <leader>ga :Agit<CR>
nnoremap <silent> <leader>go :Git checkout %<cr>
nnoremap <silent> <leader>gdi :Git diff<CR>
nnoremap <silent> <leader>gdl :Git diff @~..@<CR>

let g:glab_mr=''
nnoremap <leader>glms :let g:glab_mr=
nnoremap <leader>glml :lua RunShellAndShow('glab mr list')<cr>
nnoremap <leader>glmc :lua RunShellAndShow('glab mr checkout ' . g:glab_mr)<cr>
nnoremap <leader>glma :lua RunShellAndShow('glab mr approve ' . g:glab_mr)<cr>
nnoremap <leader>glmn :lua RunShellAndShow('glab mr note ' . g:glab_mr)<cr>
nnoremap <leader>glmm :lua RunShellAndShow('glab mr merge ' . g:glab_mr)<cr>
nnoremap <leader>glmv :lua RunShellAndShow('glab mr view ' . g:glab_mr)<cr>

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
"nnoremap <leader>co  " for rnadom colorscheme

nnoremap <leader>fx :Explore<space>
nnoremap <leader>fr :Explore scp://
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
nnoremap <silent> <leader>qs <cmd>lua require("persistence").load()<cr>

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
nnoremap <silent> <leader>sm <cmd>lua ToggleMouse()<cr>
nnoremap <silent> <leader>ss <cmd>lua ToggleStatusLine()<cr>
nnoremap <silent> <leader>sl <cmd>lua ToggleIndentLine()<cr>
nnoremap <silent> <leader>si :source Session.vim<cr>
nnoremap <silent> <leader>se :mksession!<cr>
nnoremap <silent> <leader>sc <cmd>lua ToggleForCopy()<cr>
nnoremap <silent> <leader>st :Switch<cr>
nnoremap <silent> <leader>sk :DisableTmuxKey<cr>
nnoremap <silent> <leader>so :TSContextToggle<cr>

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

nnoremap <silent> <leader>ed :e <c-r>=expand("%:p:h")<cr>/<cr>
nnoremap <silent> <leader>eu :UndotreeToggle<cr>
nnoremap <silent> <leader>esi <cmd>lua EditFile(vim.env.MYVIMRC)<cr>
nnoremap <silent> <leader>esl <cmd>lua EditFile('~/.vim_custom.vim')<cr>
nnoremap <silent> <leader>esc <cmd>lua EditFile('~/.config/nvim/config.lua')<cr>
nnoremap <silent> <leader>esj <cmd>call EditTodayNote()<cr>
nnoremap <silent> <leader>er :registers<cr>
nnoremap <leader>ef :set filetype=
nnoremap <leader>ea :filetype detect<cr>
nnoremap <silent> <leader>eg :Grepper<cr>
nnoremap <silent> <leader>ej ::%!jq '.'<cr>
nnoremap <leader>ee :terminal<space>

nnoremap <silent> <leader>en :echo getcwd()<cr>
nnoremap <silent> <leader>em :Pushd <c-r>=expand("%:p:h")<cr><cr>
nnoremap <silent> <leader>ecr :let @a=@%<cr>
nnoremap <silent> <leader>ecn :let @a=expand("%:t")<cr>
nnoremap <silent> <leader>ecf :let @a=expand("%:p")<cr>
nnoremap <silent> <leader>ecd :let @a=expand("%:p:h")<cr>

nnoremap <silent> <leader>pp :put<cr>
nnoremap <silent> <leader>pr :put<cr>G$a<cr>
nnoremap <leader>pi :lua MyRun({"FloatermNew --autoclose=1 nvim '+silent! PlugInstall' '+silent! TSUpdateSync' +qall"})<cr>
nnoremap <leader>pu :lua MyRun({"FloatermNew --autoclose=1 nvim '+silent! PlugUpgrade' '+silent! PlugUpdate' '+silent! TSUpdateSync' +qall"})<cr>

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


{% if nvim %}
" open new terminal in new tab/buffer.
nnoremap <silent> <leader>tt :tabnew <cr>:terminal<cr>
nnoremap <silent> <leader>tb :split<cr><c-w>j:terminal<cr>
nnoremap <silent> <leader>tv :vsplit<cr><c-w>l:terminal<cr>


{% endif %}

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
nnoremap <silent> <leader>lf <cmd>lua LspFormat()<cr>
vnoremap <silent> <leader>lf <cmd>lua vim.lsp.buf.range_formatting()<cr>
vnoremap <silent> f <cmd>lua vim.lsp.buf.range_formatting()<cr>
nnoremap <silent> <leader>li <cmd>lua require'fzf_lsp'.implementation_call()<cr>
nnoremap <silent> <leader>lsa <cmd>lua vim.lsp.buf.signature_help()<cr>
nnoremap <silent> <leader>lsy <cmd>lua require'fzf_lsp'.document_symbol_call()<cr>
nnoremap <silent> <leader>lsY <cmd>lua require'fzf_lsp'.workspace_symbol_call()<cr>
nnoremap <silent> <leader>lsc <cmd>lua require'fzf_lsp'.incoming_calls_call()<cr>
nnoremap <silent> <leader>lsC <cmd>lua require'fzf_lsp'.outcoming_calls_call()<cr>

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
nnoremap <silent> <localleader>g :ChooseWin<cr>
nnoremap <silent> <localleader>t :tabnew %<cr>
nnoremap <silent> <localleader>h :wincmd h<cr>
nnoremap <silent> <localleader>j :wincmd j<cr>
nnoremap <silent> <localleader>k :wincmd k<cr>
nnoremap <silent> <localleader>l :wincmd l<cr>
nnoremap <silent> <localleader>o :JABSOpen<cr>
nnoremap <silent> <localleader>q :q!<cr>
nnoremap <silent> <localleader>p :Files<cr>
nnoremap <silent> <localleader>t :tabnew %<cr>
nnoremap <localleader>rr :lua MyRun({''})<left><left><left>
nnoremap <localleader>e :lua RunShellAndShow('')<left><left>

xnoremap iu :lua require"treesitter-unit".select()<CR>
xnoremap au :lua require"treesitter-unit".select(true)<CR>
onoremap iu :<c-u>lua require"treesitter-unit".select()<CR>
onoremap au :<c-u>lua require"treesitter-unit".select(true)<CR>

nnoremap <leader>dg :silent exec '!bb "go <c-r>=&filetype<cr><space>"'<left><left>
nnoremap <leader>dd :silent exec '!bb "https://devdocs.io/<c-r>=&filetype<cr>"'<cr>

nnoremap <leader>xx <cmd>TroubleToggle<cr>
nnoremap <leader>xw <cmd>TroubleToggle workspace_diagnostics<cr>
nnoremap <leader>xd <cmd>TroubleToggle document_diagnostics<cr>
nnoremap <leader>xq <cmd>TroubleToggle quickfix<cr>
nnoremap <leader>xl <cmd>TroubleToggle loclist<cr>
