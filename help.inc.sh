#!/bin/sh

usage() {
  {
    echo "usage: $0 <peer name or fingerprint>"

    echo "own private keys: (share public key with 'gpg --armour --export ...id...')"
    gpg --list-secret-keys --fingerprint |
    highlight_gpg_id

    echo "known public keys: (import with 'gpg --import file.gpg; gpg --edit-key ... # trust ultimate')"
    gpg --list-public-keys --fingerprint |
    highlight_gpg_id
  } >&2
  exit 1
}

highlight_gpg_id() {
 sed -nr "
  s~\s*Key fingerprint = .* ([0-9A-F]{4}) ([0-9A-F]{4}) ([0-9A-F]{4}) ([0-9A-F]{4})$~ id   \1\2\3\4~
  t p
  s~^(uid|sec)\>~&~
  T e
  :p
  s~^~#### ~
  p
  :e
 "
}
