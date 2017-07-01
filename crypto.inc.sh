#!/bin/sh

encode() {
  gpg -aer "$PEER" |
  sed ":l; N; s~\n~<~; t l"
}

decode() {
  sed -r "
    s~^.*(-----BEGIN PGP MESSAGE-----)~\1~g
    s~<~\n~g
  " |
  if ! gpg -ad 2>/dev/null; then
    msg_decode_error
  fi
}
