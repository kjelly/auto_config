let all_path = ['~/gohome/bin', '~/go/bin/', '~/bin', '~/mybin', '~/dark-sdk/bin',
                 '~/swif/usr/bin', '/usr/local/mercury*/bin',
                 '/usr/lib/dart/bin/', '~/.cargo/bin/', '~/sbt/bin',
                 '~/.pub-cache/bin', '~/dart-sdk/bin', '~/activator/bin/',
                 '~/google-cloud-sdk/bin/', '~/kotlinc/bin/', '~/.rvm/bin',
                 '/snap/bin/', '~/flutter/bin/', '~/.local/bin', '~/.deno/bin/',
                 '~/flutter/bin/cache/dart-sdk/bin',
                 '~/nfs/bin/', '~/.pub-cache/bin', '~/anaconda3/bin/',
                 '~/node*/bin', '~/.asdf/installs/python/*/bin', '~/pypy*/bin/',
                 '~/.fzf/bin/', '~/.asdf/bin/', '~/.asdf/shims/',

                 ]
$env.PATH = ($env.PATH | prepend ($all_path | each {|it| glob $it}|flatten -a |uniq))
