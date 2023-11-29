$env.NU_LIB_DIRS = ($env.NU_LIB_DIRS | prepend (ls ~/nu_scripts/modules/ | get name))
