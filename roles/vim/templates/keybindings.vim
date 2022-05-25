nnoremap H :tabprevious<cr>
nnoremap L :tabnext<cr>
nnoremap ; <cmd>FineCmdline<CR>

"bash like keybinding
" <c-a> for <home>, <c-e> for <end>
" <c-d> for <delete>,
" <c-h> will be overrided for <left>
inoremap <c-a> <home>
inoremap <c-e> <end>
inoremap <c-d> <delete>
inoremap <c-;> <delete>

cnoremap <silent> <c-e> <Esc>:History:<cr>

" Use normal regex
" http://stevelosh.com/blog/2010/09/coming-home-to-vim
nnoremap / /\v
vnoremap / /\v

inoremap <S-Tab> <Esc><<i
nnoremap <S-Tab> <<
nnoremap <Tab> >>

nnoremap <a-f> <c-w>w

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
  elseif exists(":NvimTreeToggle")
    execute "NvimTreeToggle"
  elseif exists(":NERDTreeToggle")
    execute "NERDTreeToggle"
  endif
endfunction
nnoremap <C-n> :call TreeToggle()<cr>
nnoremap <C-t> :tabnew %<CR>
inoremap <C-t> <Esc>:tabnew %<CR>

" Command
nnoremap <C-e> :Commands<cr>

" Tag list
nnoremap <C-s> :Vista!!<cr>

inoremap <C-s> <Esc>:w<cr>a

inoremap <expr> <Esc>      pumvisible() ? "\<C-e>" : "\<Esc>"
inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"
inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"
inoremap <expr> <PageDown> pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<PageDown>"
inoremap <expr> <PageUp>   pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<PageUp>"
if exists(':CocOpenLog')
  inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                                \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
endif

" Find file
function FindFile()
  call system("git status")
  if v:shell_error == 0
    execute 'GitFiles'
    return
  else
    execute 'Files'
  endif
endfunction
nnoremap <C-p> :call FindFile()<cr>
vnoremap <c-p> "ry:<c-u>Rg <c-r>r<cr>

" Insert mode completion
imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)

cnoremap <c-s> Explore scp://

" Use Enter to expand snippet. This is for nvim-completion-manager.
"imap <expr> <CR>  (pumvisible() ?  "\<c-y>\<Plug>(expand_or_nl)" : "\<CR>")
"imap <expr> <Plug>(expand_or_nl) (cm#completed_is_snippet() ? "\<Tab>":"\<CR>")

{% if nvim %}
tnoremap <C-]> <C-\><C-n>:call TermToggle()<cr>

{% endif %}
inoremap <C-]> <Esc>:call TermToggle()<cr>
vnoremap <C-]> <Esc>:call TermToggle()<cr>
cnoremap <C-]> <Esc>:call TermToggle()<cr>
nnoremap <C-]> :call TermToggle()<cr>

{% if nvim %}
" If we need Esc in terminal buffer,
" just unmap it.
tnoremap <expr> <silent> <Esc> &filetype=='fzf' ? '<C-\><C-n>:close<cr>' : '<C-\><C-n>'
"tunmap <Esc> <C-\><C-n>

{% endif %}

vnoremap > >gv
vnoremap < <gv

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

{% endif %}

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

vmap <C-c> y:call SendViaOSC52(getreg('"'))<cr>

{% if nvim %}

" Since I use hterm in tab, I need another key for <c-w>
imap <a-bs> <c-w>
nmap <a-bs> <c-w>
tmap <a-bs> <c-w>

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

imap <A-p> <c-p>
nmap <A-p> <c-p>
tmap <A-p> <c-p>
cmap <A-p> <c-p>
nmap <A-n> <c-n>
if exists('CocOpenLog')
inoremap <silent><expr> <A-n>
      \ pumvisible() ? "\<C-n>" :
      \ coc#refresh()
else
imap <A-n> <c-n>
endif
tmap <A-n> <c-n>
cmap <A-n> <c-n>

inoremap <A-o> <Esc>:Buffers<cr>
nnoremap <expr> <A-o> &filetype=='floaterm' ? ':Floaterms<cr>' : ':Buffers<cr>'
tnoremap <A-o> <C-\><C-n>:Floaterms<cr>

inoremap <A-u> <Esc>:History:<cr>
nnoremap <A-u> :History:<cr>
tnoremap <A-u> <C-\><C-n>:History:<cr>

" buufer switch
nnoremap <expr> <A-d> &filetype=="floaterm" ? ":FloatermPrev<cr>" : "<c-^>"
inoremap <A-d> <Esc><c-^>a
tnoremap <A-d> <C-\><C-n>:FloatermNext<cr>i

" save
nnoremap <A-s> :w<cr>
inoremap <A-s> <Esc>:w<cr>
tnoremap <A-s> <C-\><C-n>

imap <a-w> <c-w>
nmap <a-w> <c-w>
tmap <a-w> <c-w>
cmap <a-w> <c-w>
vmap <a-w> <c-w>

" Paste text
tnoremap <A-v> <C-\><C-n>pi
inoremap <A-v> <Esc>pi

nnoremap <A-r> :lua MyRun()<cr>
inoremap <A-r> <Esc>:lua MyRun()<cr>
tnoremap <A-r> <c-\><c-n>:lua MyRun()<cr>
nnoremap <A-e> :call RunShellAndShow('')<left><left>
inoremap <A-e> <Esc>:call RunShellAndShow('')<left><left>
" tnoremap <A-e> <c-\><c-n>:call RunShellAndShow('')<left><left> " needed by br

imap <A-g> <Esc><Plug>(choosewin)
nmap <A-g> <Plug>(choosewin)
tmap <A-g> <C-\><C-n><Plug>(choosewin)

inoremap <A-m> <Esc>:Marks<cr>
nnoremap <A-m> :Marks<cr>

inoremap <a-;> <Esc>:call TermToggle()<cr>
nnoremap <a-;> :call TermToggle()<cr>
tnoremap <a-;> <c-\><c-n>:call TermToggle()<cr>

inoremap <silent> <a-:> <Esc>:FloatermNew<cr>
nnoremap <silent> <a-:> :FloatermNew<cr>
tnoremap <silent> <a-:> <c-\><c-n>:FloatermNew<cr>

nnoremap <silent> <a-'> :FloatermNext<cr>
tnoremap <silent> <a-'> <c-\><c-n>:FloatermNext<cr>i

inoremap <silent> <a-"> <Esc>:FloatermPrev<cr>
nnoremap <silent> <a-"> :FloatermPrev<cr>
tnoremap <silent> <a-"> <c-\><c-n>:FloatermPrev<cr>

inoremap <silent> <a-Enter> <Esc>:FloatermSend<cr>
nnoremap <silent> <a-Enter> :FloatermSend<cr>
" tnoremap <silent> <a-Enter> <c-\><c-n>:FloatermSend<cr> " needed by br
vnoremap <silent> <a-Enter> :FloatermSend<cr>

inoremap <silent> <s-a-enter> <Esc>:%FloatermSend<cr>
nnoremap <silent> <s-a-enter> :%FloatermSend<cr>

" Location list
inoremap <A-[> <Esc>:lp<cr>
nnoremap <A-[> :lp<cr>
tnoremap <A-[> <C-\><C-n><C-w>:lp<cr>
inoremap <A-]> <Esc>:lne<cr>
nnoremap <A-]> :lne<cr>
tnoremap <A-]> <C-\><C-n><C-w>:lne<cr>

inoremap <A-c> <Esc>:lua multiTermRunCurrentLine()<cr>i
nnoremap <A-c> <Esc>:lua multiTermRunCurrentLine()<cr>
nnoremap <A-x> <Esc>:lua multiTermRunCurrentSelectedLines()<cr>
vnoremap <A-x> :lua multiTermRunCurrentSelectedLines()<cr>

let g:maxWindow=0
function ResizeWin()
  if g:maxWindow == 0
    resize +2000
    let g:maxWindow=1
  else
    wincmd =
    let g:maxWindow=0
  endif
endfunction

inoremap <a-`> <Esc>:call ResizeWin()<cr>a
nnoremap <a-`> :call ResizeWin()<cr>
tnoremap <a-`> <c-\><c-n>:call ResizeWin()<cr>a

nnoremap <a-q> :call jobstart('workspace')<cr>

if exists(':CocOpenLog')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <c-g> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <c-g> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <c-g> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
else
  nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>
  nnoremap <silent> gD <cmd>lua vim.lsp.buf.declaration()<CR>
  nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
  nnoremap <silent> gi <cmd>lua vim.lsp.buf.implementation()<CR>
  nnoremap <silent> <leader>ld <cmd>lua vim.diagnostic.open_float()<CR>
  nnoremap <silent> [d <cmd>lua vim.diagnostic.goto_prev()<CR>
  nnoremap <silent> ]d <cmd>lua vim.diagnostic.goto_next()<CR>
endif

{% endif %}
