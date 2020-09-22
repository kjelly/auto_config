set __oceanfish_glyph_anchor \u2693
set __oceanfish_glyph_flag \u2691
set __oceanfish_glyph_radioactive \u2622
set arrow \u21d2


function _git_branch_name
    echo (__fish_git_prompt)
end


function _is_git_dirty
    echo (command git status -s --ignore-submodules=dirty ^/dev/null)
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
    if [ (_git_branch_name) ]
        set -l git_branch (_git_branch_name)
        if [ (_is_git_dirty) ]
            echo -n -s $magenta "$git_branch " $red "$__oceanfish_glyph_flag "
        else
            echo -n -s $magenta "$git_branch "
        end
    end

    if test $last_status -ne 0
      set last_status_color $red
    else
      set last_status_color $normal
    end
    echo -n -s $last_status_color ' [' $last_status ']' $normal


    # Terminate with a space
    echo
    if [ $uid -eq 0 ]
        echo -n -s '# ' $normal
    else
        echo -n -s '$ ' $normal
    end
end


