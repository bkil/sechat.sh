#!/bin/sh

usage() {
  {
    echo "client usage: $0 <peer name or fingerprint> <server host> <server port>"
    echo "server usage: $0 <peer name or fingerprint> <listen port>"

    echo "own private keys:"
    gpg --list-secret-keys --fingerprint |
    highlight_gpg_id

    echo "known public keys:"
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
