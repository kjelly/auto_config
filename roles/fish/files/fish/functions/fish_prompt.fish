function _git_branch_name
    echo (__fish_git_prompt)
end

function command_run_time
    if test $CMD_DURATION
        # Show duration of the last command in seconds
        set duration (echo "$CMD_DURATION 1000" | awk '{printf "%.3fs", $1 / $2}')
        echo $duration
    end
    echo "😄"
end

function fish_prompt
    set -l last_status $status
    set -l magenta (set_color magenta)
    set -l red (set_color red)
    set -l cyan (set_color cyan)
    set -l white (set_color white)
    set -l black (set_color black)
    set -l bg_blue (set_color -b blue)
    set -l bg_cyan (set_color -b cyan)
    set -l bg_white (set_color -b white)
    set -l bg_red (set_color -b red)
    set -l bg_yellow (set_color -b yellow)
    set -l normal (set_color normal)
    set -l cwd (python3 ~/.config/fish/print_cwd.py $PWD)
    set -l uid (id -u $USER)

    set -l host_info_color_bg "143"
    set -l host_info_color_fg "A3C"

    set -l cwd_color_bg "148"
    set -l cwd_color_fg "9AD"

    # Display virtualenv name if in a virtualenv
    if set -q VIRTUAL_ENV
        echo -n -s $bg_cyan $black " " (basename "$VIRTUAL_ENV") " " $normal
    end

    set_color $host_info_color_fg
    echo -n -s (whoami) "@" (hostname -s) " "

    # Display current path
    set_color $cwd_color_fg
    echo -n -s "$cwd"


    # Show git branch and dirty state
    fish_git_prompt


    if test $last_status -ne 0
      set last_status_color $red
      echo -n ' ❌'
    else
      set last_status_color $normal
    end
    echo -n -s $last_status_color ' [' $last_status '] ' $normal (command_run_time)



    # Terminate with a space
    echo
    if [ $uid -eq 0 ]
        echo -n -s '# ' $normal
    else
        echo -n -s '$ ' $normal
    end
end


