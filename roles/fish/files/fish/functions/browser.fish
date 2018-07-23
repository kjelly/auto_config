function browser
    set keyword $argv[1]
    w3m "https://duckduckgo.com/?q=$keyword"
end
