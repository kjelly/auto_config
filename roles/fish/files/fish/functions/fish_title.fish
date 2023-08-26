function fish_title
    if test -z "$TMUX"
      echo "@"(hostname)":" 
    end
    if test -z "$argv"
      echo 'fish '
    else
      echo $argv ' '
    end
end
