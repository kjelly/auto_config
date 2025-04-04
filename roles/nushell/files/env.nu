let all_path = ['~/bin', '~/mybin', '~/dark-sdk/bin',
                 '~/swif/usr/bin', '/usr/local/mercury*/bin',
                 '~/.cargo/bin/', '~/sbt/bin',
                 '~/.pub-cache/bin', '~/dart-sdk/bin', '~/activator/bin/',
                 '~/google-cloud-sdk/bin/', '~/kotlinc/bin/', '~/.rvm/bin',
                 '/snap/bin/', '~/flutter/bin/', '~/.local/bin', '~/.deno/bin/',
                 '~/nfs/bin/', '~/.pub-cache/bin', '~/anaconda3/bin/',
                 '~/node*/bin', '~/.asdf/installs/python/*/bin', '~/pypy*/bin/',
                 '~/.fzf/bin/', '~/.asdf/bin/', '~/.asdf/shims/',
                 ]
$env.PATH = ($env.PATH | append ($all_path | each {|it| glob $it}|flatten -a |uniq) | uniq)
