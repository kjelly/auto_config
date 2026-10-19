" Commands shared by the configured keymaps.
command! -bang Bclose lua require('config.buffers').close(<q-bang> == '!')
command! SearchPanel lua require('grug-far').open()
command! Br lua KillAndRerunTerm('br', 'br', {autoclose=true})
command! FormatJson %!python3 -m json.tool

function! s:DiffWithSaved()
  let filetype=&ft
  diffthis
  vnew | r # | normal! 1Gdd
  diffthis
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype
endfunction

function! FindFileInTree()
  Neotree reveal
endfunction

function! EditTodayNote() abort
  let l:directory = expand('~/notes/journals/')
  call mkdir(l:directory, 'p')
  let l:file = l:directory . strftime('%Y-%m-%d.md')
  let l:template = expand('~/notes/templates/daily template.md')
  if !filereadable(l:file) && filereadable(l:template)
    call writefile(readfile(l:template), l:file)
  endif
  execute 'edit' fnameescape(l:file)
endfunction

augroup ConfigBasic
  autocmd!
  autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line('$') | execute "normal! g`\"" | endif
  autocmd TermOpen * setlocal nonumber norelativenumber signcolumn=no
  autocmd BufWritePost workspace.vim execute 'source' fnameescape(expand('<afile>'))
  autocmd BufRead,BufNewFile /tmp/*.nu setlocal bufhidden=delete
  autocmd BufRead,BufNewFile /tmp/*.nu nnoremap <buffer> <c-s> <cmd>wq<cr>|inoremap <buffer> <c-s> <cmd>wq<cr>
augroup END

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
command! W SudaWrite

command! Cd1 :cd ..
command! Cd2 :cd ../..
command! Cd3 :cd ../../..
command! E Oil

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

command! Vifm lua KillAndRerunTerm('vifm', 'vifm -c only', {shell=true})
command! NNN lua KillAndRerunTerm('nnn', 'nnn', {shell=true})
command! FFF lua KillAndRerunTerm('fff', 'fff', {shell=true})

command! -nargs=* NoteSearch lua require('fzf-lua').live_grep({cwd=vim.fn.expand('~/notes'), search=<q-args>})
command! Note lua require('fzf-lua').files({cwd=vim.fn.expand('~/notes')})

command! DisableTmuxKey
         \ call jobstart('set-tmux-prefix -k F1 -t 20', {
         \    'on_exit': { j,d,e ->
         \       execute('echom "enable tmux key"', '')
         \    }
         \ })



" Yank to system clipboard with Y
nnoremap YY "+yy
nnoremap Y "+y
vnoremap Y "+y
