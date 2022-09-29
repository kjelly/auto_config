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

nnoremap <tab> <cmd><plug>(CybuLastusedNext)<cr>
nnoremap <s-tab> <cmd><plug>(CybuLastusedPrev)<cr>

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

" Command
nnoremap <c-e> :Commands<cr>

nnoremap <m-s> <cmd>lua SymbolToggle()<cr>

" save
nnoremap <c-s> <cmd>w<cr>
inoremap <c-s> <cmd>w<cr><esc>
tnoremap <c-s> <C-\><C-n> " exit terminal

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

cnoremap <c-s> Explore scp://

{% if nvim %}

tnoremap <c-]> <cmd>stopinsert<cr>

{% endif %}
inoremap <c-]> <Esc>
vnoremap <c-]> <Esc>
cnoremap <c-]> <Esc>
nnoremap <c-]> <Esc>

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

cnoremap <m-h> <Left>
cnoremap <m-j> <Down>
cnoremap <m-k> <Up>
cnoremap <m-l> <Right>

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

inoremap <m-o> <cmd>FzfLua buffers<cr>
nnoremap <m-o> <cmd>FzfLua buffers<cr>
tnoremap <m-o> <cmd>FzfLua buffers<cr>

inoremap <m-i> <cmd>FzfLua resume<cr>
nnoremap <m-i> <cmd>FzfLua resume<cr>
tnoremap <m-i> <cmd>FzfLua resume<cr>

inoremap <m-u> <cmd>FzfLua live_grep_native<cr>
function! CallHistoryShell()
  execute feedkeys("fzf-history-widget")
  execute feedkeys("\<CR>")
  if mode() != 't'
    startinsert
  endif
endfunction
nnoremap <expr> <m-u> &filetype=='floaterm' ? ':call CallHistoryShell()<cr>' : ':FzfLua live_grep_native<cr>'
tnoremap <m-u> <cmd>calll CallHistoryShell()<cr>
vnoremap <m-u> "ry:<c-u>Rg <c-r>r<cr>

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

inoremap <m-q> <cmd>lua ResizeWin()<cr>
nnoremap <m-q> <cmd>lua ResizeWin()<cr>
tnoremap <m-q> <cmd>lua ResizeWin()<cr>

nnoremap <m-`> :call jobstart('workspace')<cr>

nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> gi <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> [d <cmd>lua vim.diagnostic.goto_prev({severity=vim.diagnostic.severity.INFO})<CR>
nnoremap <silent> ]d <cmd>lua vim.diagnostic.goto_next({severity=vim.diagnostic.severity.INFO})<CR>

{% endif %}
