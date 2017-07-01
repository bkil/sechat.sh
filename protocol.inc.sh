#!/bin/sh

msg_heartbeat() {
  printf "<heartbeat>"
}

msg_decode_error() {
  printf "<error: decoding malformed message>"
}

msg_greet() {
  printf "<hi>"
}

msg_exit() {
  printf "<bye>"
}
