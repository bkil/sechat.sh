#!/bin/bash
#BASHisms:
# * read -t
#
#Requirements:
# * gnupg
# * nc / netcat
# * stunclient
#
# TODO:
# * exchange random key via GnuPG and encrypt using that

imports() {
  . `mkpath stun.inc.sh`
  . `mkpath help.inc.sh`
  . `mkpath crypto.inc.sh`
  . `mkpath protocol.inc.sh`
}

main() {
  imports

  PEER="$1"
  if [ $# -eq 1 ]; then
    local PORT="`bind_stun`"
    server "$PORT"

  elif [ $# -eq 2 ]; then
    /sbin/ifconfig eth0 |
    grep 'inet addr'

    server "$2"

  elif [ $# -eq 3 ]; then
    client "$2" "$3"

  else
    usage
  fi
}

server() {
  local PORT="$1"

  NC="nc -vvl $PORT"
  loop
}

client() {
  local HOST="$1"
  local PORT="$2"

  NC="nc -vv $HOST $PORT"
  loop
}

loop() {
  HEARTBEATINTERVAL=10
  {
    msg_greet |
    encode

    handle_keyboard

    msg_exit |
    encode

    sleep 1
  } |
  $NC -q 1 -u |
  handle_network
}

handle_keyboard() {
  local LINE=0
  while
    read -t $HEARTBEATINTERVAL TEXT 2>/dev/null
    local STATUS=$?
    [ $STATUS -ne 1 ]
  do
    if [ $STATUS -eq 0 ]; then
      echo "[$LINE] $TEXT" |
      encode
      printf "[$LINE] " >&2
      local LINE=`expr $LINE + 1`
    else
      msg_heartbeat |
      encode
    fi
  done
}

handle_network() {
  local BEATDEADLINE=`expr $HEARTBEATINTERVAL + 5`
  while
    read -t $BEATDEADLINE ENCODED
  do
    local DECODED="`echo "$ENCODED" | decode`"
    if [ "$DECODED" != "`msg_heartbeat`" ]; then
      echo " > `date +%H:%M` $PEER $DECODED"
      [ "$DECODED" = "`msg_exit`" ] &&
        kill $$
    fi
  done
  echo "error: skipped heartbeat / EOF" >&2
  kill $$
}

mkpath() {
  local OWNDIR="`dirname "$0"`"
  local FILE="$1"
  if [ -z "$OWNDIR" ]; then
    echo "$FILE"
  else
    echo "$OWNDIR/$FILE"
  fi
}

main "$@"
