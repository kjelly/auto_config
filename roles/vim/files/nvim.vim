" Compatibility entry point for commands and keymaps.
let s:config_dir = stdpath('config') . '/lua/config/'
execute 'source' fnameescape(s:config_dir . 'commands.vim')
execute 'source' fnameescape(s:config_dir . 'keymaps.vim')
