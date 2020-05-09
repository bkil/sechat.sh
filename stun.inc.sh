#!/bin/sh

bind_stun() {
  local TRYPORT=34210
  local LASTPORT=34220
  while true; do
    local PORT_EXTERNAL=`rebind_stun $TRYPORT`
    local PORT=`echo "$PORT_EXTERNAL" | cut -d " " -f 1`
    local EXTERNAL=`echo "$PORT_EXTERNAL" | cut -d " " -f 2-`
    if [ -n "$EXTERNAL" ]; then
      break
    elif [ -z "$TRYPORT" ]; then
      echo "error: stun binding failed, try to forward or map a port manually" >&2
      exit 1
    elif [ "$TRYPORT" -ge "$LASTPORT" ]; then
      local TRYPORT=""
      exit 1 ##
    else
      local TRYPORT=`expr "$TRYPORT" + 1`
      printf .
      sleep 1
    fi
  done
  echo "info: Tell this mapped address to your remote peer: $EXTERNAL" >&2
  echo "$EXTERNAL"
}

rebind_stun() {
  # http://olegh.ftp.sh/public-stun.txt
  # stunclient stunserver.org 3478

  if [ $# -eq 1 ]; then
    local REQUESTPORT="--localport $1"
  else
    local REQUESTPORT=""
  fi
  local STUN="stun.justvoip.com 3478"
  local RESULT="`stunclient $REQUESTPORT $STUN`"
  local PORT=`echo "$RESULT" |
    sed -nr "s~^(|.*\n)Local address: [^\n]*:([^:\n]+)(|\n.*)$~\2~; T e; p; :e"`
  local EXTERNAL=`echo "$RESULT" |
    sed -nr "s~^Mapped address: (.*)$~\1~; T e; p; :e"`
  echo $PORT $EXTERNAL
}
