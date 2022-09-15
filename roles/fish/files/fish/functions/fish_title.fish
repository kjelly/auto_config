function fish_title
    if test -z "$argv"
      echo 'fish '
    else
      echo $argv ' '
    end
    if set -q IN_VIM
      echo $USER
      echo '@'
      hostname
      echo ':'
      pwd
      echo ' '
    end
end
