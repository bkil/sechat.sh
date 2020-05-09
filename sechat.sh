#!/bin/bash
#BASHisms:
# * read -t
#
#Requirements:
# * gnupg
# * nc / netcat
# * stunclient (stuntman-client)
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
  if [ $# -eq 2 ]; then
    /sbin/ifconfig |
    grep 'inet addr' |
    grep -vE "\<(127|172)\.[0-9]+\.[0-9]+\.[0-9]"

    server "$2"

  elif [ $# -eq 1 ]; then
    EXTERNAL="`bind_stun`"
    local LHOST="`echo "$EXTERNAL" | cut -d : -f 1`"
    local LPORT="`echo "$EXTERNAL" | cut -d : -f 2`"

    while [ -z "$ADDR" ] || [ "$ADDR" = "$EXTERNAL" ]; do
      read -p "Please enter the 'Mapped address' of your peer: " ADDR
    done

    local PHOST="`echo "$ADDR" | cut -d : -f 1`"
    local PPORT="`echo "$ADDR" | cut -d : -f 2`"

    FIRST="`{ echo $LHOST; echo $PHOST ;}|sort|head -n 1`"
    if [ "$FIRST" = "$LHOST" ]; then
#      echo | nc -vvp "$LPORT" -w 1 "$PHOST" "$PPORT"
      echo | nc -vvup "$LPORT" -w 1 "$PHOST" "$PPORT"
      server "$LPORT"
    else
      client "$LPORT" "$PHOST" "$PPORT"
    fi
  else
    usage
  fi
}

server() {
  local PORT="$1"

  NC="nc -l $PORT"
  loop
}

client() {
  local LPORT="$1"
  local HOST="$2"
  local PORT="$3"

  NC="nc -p $LPORT $HOST $PORT"
  loop
}

loop() {
  HEARTBEATINTERVAL=30
  {
    msg_greet |
    encode

    handle_keyboard

    msg_exit |
    encode

    sleep 1
  } |
  $NC -vv -q 1 -u |
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
