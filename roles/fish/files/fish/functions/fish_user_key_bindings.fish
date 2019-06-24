function fish_notify
       commandline -i -- ";hterm-notify.sh done "
end

function fish_user_key_bindings
    #fish_vi_key_bindings
    fish_default_key_bindings
    fzf_key_bindings
    bind \af "forward-word"
    bind \ab "backward-word"
    bind \ei fish_notify
end

