function fcd
    if count $argv > /dev/null
        set base $argv
    else
        set base "."
    end

    tree -if --noreport $base|fzf > ~/.fcd
    set cd_path (cat ~/.fcd)
    if [ $cd_path ]
        if [ -d $cd_path ]
            cd $cd_path
        else
            cd (dirname $cd_path)
        end
    end
end


