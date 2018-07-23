function weather
    set city $argv[1]
    curl wttr.in/$city
end



