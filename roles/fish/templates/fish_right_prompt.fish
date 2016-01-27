function right_prompt_segment -d "Function to draw a right segment"
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
  if [ "$agnoster_right_current_bg" != 'NONE' -a "$argv[1]" != "$agnoster_right_current_bg" ]
    set_color -b $agnoster_right_current_bg
    set_color $bg
    echo -n " $right_segment_separator"
    set_color -b $bg
    set_color $fg
  else
    set_color -b $bg
    set_color $fg
  end
  set agnoster_right_current_bg $argv[1]
  if [ -n "$argv[3]" ]
    echo -n -s " " $argv[3]
  end
end

function end_right_prompt
  if [ -n $agnoster_right_current_bg ]
        set_color -b normal
        set_color $agnoster_right_current_bg
  end
  set -g agnoster_right_current_bg NONE
end

function fish_right_prompt -d 'about the right prompt'
  set -l last_status $status
  set -q theme_date_format; or set -l theme_date_format "+%c"

  set datetime (date $theme_date_format)

  right_prompt_segment normal $fish_color_autosuggestion[1] "[ $last_status ]"
  right_prompt_segment normal $fish_color_autosuggestion[1] $datetime

  #end_right_prompt
  set_color normal
end

