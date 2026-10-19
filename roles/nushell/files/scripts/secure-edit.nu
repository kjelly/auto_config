# Explicit --key wins over the environment; recipient derivation never prints
# identity contents and also works when the key file has no public-key comment.
def sops-age [file: path, --key: path] {
  let identity = ($key | default ($env.SOPS_AGE_KEY_FILE? | default '~/.ssh/age-key.txt') | path expand)
  let result = (^age-keygen -y $identity | complete)
  if $result.exit_code != 0 { error make {msg: 'Unable to derive the age recipient from the selected identity'} }
  let recipients = ($result.stdout | lines | str trim | where {|line| $line != '' } | str join ',')
  if $recipients == '' { error make {msg: 'Selected identity has no age recipients'} }
  with-env {SOPS_AGE_KEY_FILE: $identity} {
    ^sops edit --age $recipients -- $file
  }
}

# Plaintext lives in a private directory. Encrypt to the destination filesystem
# and rename only after every stage succeeds; failure leaves the original intact.
def age-edit [file: path, --key: string = 'simple'] {
  let target = ($file | path expand)
  let identity = ($env.HOME | path join '.ssh' $key | path expand)
  let temporary = (^mktemp -d | complete)
  if $temporary.exit_code != 0 { error make {msg: 'Unable to create private editing directory'} }
  let directory = ($temporary.stdout | str trim)
  let destination = (^mktemp -d $"--tmpdir=($target | path dirname)" '.age-edit.XXXXXXXXXX' | complete)
  if $destination.exit_code != 0 {
    rm --recursive --permanent --force $directory
    error make {msg: 'Unable to create staging directory; original preserved'}
  }
  let staged_dir = ($destination.stdout | str trim)
  let plain = ($directory | path join 'edit')
  let staged = ($staged_dir | path join 'encrypted')
  try {
    let decrypted = (^age --decrypt --identity $identity --output $plain $target | complete)
    if $decrypted.exit_code != 0 { error make {msg: 'age decryption failed; original preserved'} }
    let private = (^chmod 600 $plain | complete)
    if $private.exit_code != 0 { error make {msg: 'Unable to secure editing file; original preserved'} }
    # Disable persistent editor copies of decrypted text (swap, undo, backup, shada).
    ^nvim -n -i NONE -c 'setlocal noswapfile nobackup nowritebackup noundofile' -- $plain
    if $env.LAST_EXIT_CODE != 0 { error make {msg: 'Editor failed; original preserved'} }
    let encrypted = (^age --recipients-file $"($identity).pub" --output $staged $plain | complete)
    if $encrypted.exit_code != 0 { error make {msg: 'age encryption failed; original preserved'} }
    let permissions = (^chmod $"--reference=($target)" $staged | complete)
    if $permissions.exit_code != 0 { error make {msg: 'Unable to preserve permissions; original preserved'} }
    ^mv --force -- $staged $target
    if $env.LAST_EXIT_CODE != 0 { error make {msg: 'Unable to replace encrypted file; original preserved'} }
  } catch {|err|
    rm --recursive --permanent --force $directory
    rm --recursive --permanent --force $staged_dir
    error make $err
  }
  rm --recursive --permanent --force $directory $staged_dir
}
