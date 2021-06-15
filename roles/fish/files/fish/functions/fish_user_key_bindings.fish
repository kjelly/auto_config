function fish_notify
       commandline -i -- ";hterm-notify.sh done "
end

function workspace_func
       commandline -i -- "workspace"
end

function cd_workspace
  set --local dir (workspace -p)
  if test -n "$dir"
    cd $dir
    commandline -f repaint
  end
end

function vim_workspace
  set --local dir (workspace -p)
  if test -n "$dir"
    cd $dir
    commandline -f repaint
    vim
  end
end

function fish_user_key_bindings
    fish_vi_key_bindings
    fzf_key_bindings
    bind -M insert jk "if commandline -P; commandline -f cancel; else; set fish_bind_mode default; commandline -f backward-char force-repaint; end"
    bind -M insert \ef "forward-word"
    bind -M insert \eb "backward-word"
    bind -M insert \ep "history-search-backward"
    bind -M insert \en "history-search-forward"

    bind -M insert \ew "backward-kill-word"

    bind -M insert \cp up-or-search
    bind -M insert \cn down-or-search

    bind -M insert \cf end-of-line
    bind -M insert \ce end-of-line
    bind -M insert \ca beginning-of-line

    bind -M insert \eh backward-char
    bind -M insert \ej history-search-forward
    bind -M insert \ek history-search-backward
    bind -M insert \el forward-char

    bind -M insert \ea fish_notify
    bind -M insert \eo vim_workspace
    bind -M insert \ei cd_workspace
    bind -M insert \eu vim
end
