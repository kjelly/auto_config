set __oceanfish_glyph_anchor \u2693
set __oceanfish_glyph_flag \u2691
set __oceanfish_glyph_radioactive \u2622
set arrow \u21d2

function _git_branch_name
    echo (command git symbolic-ref HEAD ^/dev/null | sed -e 's|^refs/heads/||')
end


function _is_git_dirty
    echo (command git status -s --ignore-submodules=dirty ^/dev/null)
end

function prompt_segment -d "Function to draw a segment"
  set -l bg
  set -l fg
  if [ -n "$argv[1]" ]
    set bg $argv[1]
  else
    set bg normal
  end
  if [ -n "$argv[2]" ]
    set fg $argv[2]
  else
    set fg normal
  end
  if [ "$current_bg" != 'NONE' -a "$argv[1]" != "$current_bg" ]
    set_color -b $bg
    set_color $current_bg
    echo -n "$segment_separator "
    set_color -b $bg
    set_color $fg
  else
    set_color -b $bg
    set_color $fg
    echo -n " "
  end
  set current_bg $argv[1]
  if [ -n "$argv[3]" ]
    echo -n -s $argv[3] " "
  end
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
    set -l cwd $white(prompt_pwd)
    set -l uid (id -u $USER)
    set -l host_info (whoami)(hostname -s)
    set -l host_info_color_bg (~/.config/fish/get_color.py $host_info 1)
    set -l host_info_color_fg (~/.config/fish/get_color.py $host_info)


    # Show a yellow radioactive symbol for root privileges
    if [ $uid -eq 0 ]
        echo -n -s $bg_yellow $black " $__oceanfish_glyph_radioactive " $normal
    end


    # Display virtualenv name if in a virtualenv
    if set -q VIRTUAL_ENV
        echo -n -s $bg_cyan $black " " (basename "$VIRTUAL_ENV") " " $normal
    end


    # Show a nice anchor (turns red if previous command failed)
    if test $last_status -ne 0
        echo -n -s $bg_red $white " $__oceanfish_glyph_anchor "  $normal
    else
        echo -n -s $bg_blue $white " $__oceanfish_glyph_anchor " $normal
    end

    echo -n -s $bg_white $cyan " " (whoami) "@" (hostname -s) " " $normal

    set_color $host_info_color_fg
    #set_color -b $host_info_color_bg
    echo -n "  " (whoami) "@" (hostname -s) " " $normal

    # Display current path
    echo -n -s $bg_cyan " $cwd " $normal


    # Show git branch and dirty state
    if [ (_git_branch_name) ]
        set -l git_branch (_git_branch_name)
        if [ (_is_git_dirty) ]
            echo -n -s $bg_white $magenta " $git_branch " $red "$__oceanfish_glyph_flag " $normal
        else
            echo -n -s $bg_white $magenta " $git_branch " $normal
        end
    end

	echo

    # Terminate with a space
    echo -n -s $arrow ' ' $normal
end

