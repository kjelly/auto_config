function fish_user_key_bindings
    fish_vi_mode
    bind -M insert \cl "forward-word"
    fzf_key_bindings
end

