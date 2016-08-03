function i3term
    if test (count $argv) -gt 0
      if test -d $argv[1]
        pushd . >/dev/null
        cd $argv[1]
        set cdto $PWD
        set -e argv[1]
        popd >/dev/null
        if test (count $argv) -gt 0
            set cmd $argv[1]
        else
            set cmd ''
        end

      else
          set cmd $argv[1]
      end
    else
        set cdto $PWD
    end

    set term (egrep '^bindsym' ~/.i3/config |grep Return| cut -c26-)

    if test $cmd
        i3run $term --working-directory=$cdto -e $cmd
    else
        i3run $term --working-directory=$cdto
    end
end

