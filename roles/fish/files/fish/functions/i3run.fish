function i3run
    i3-msg "exec $argv[1..-1]"
    echo "$argv[1..-1]"
end

