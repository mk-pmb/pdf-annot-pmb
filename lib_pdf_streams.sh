#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function pdf_streams__with_each_flatdecode () {
  [ -n "$1" ] || return 4$(echo "E: $FUNCNAME: pipe command required" >&2)
  tty --silent && echo "I: $FUNCNAME: gonna read PDF data from stdin." >&2
  local LNUM=0
  local MODE=pdf
  local LN=
  local BUF=
  while IFS= read -rs LN; do
    let LNUM="$LNUM+1"
    case "$MODE:$LN" in
      pdf:'<<'*' /FlateDecode>>' ) BUF=; MODE=flate;;
      flate:stream ) MODE=stream;;
      flate:* )
        echo "E: $FUNCNAME: line $LNUM: expected 'stream' but got '$LN'" >&2
        return 10;;
      stream:*endstream )
        BUF+="${LN%endstream}"
        <<<"$BUF" zlib-flate -uncompress | "$@"
        BUF="${PIPESTATUS[*]}"
        let BUF="${BUF// /+}"
        [ "$BUF" == 0 ] || return "$BUF"
        BUF=
        MODE=pdf;;
      stream:* ) BUF+="$LN"$'\n';;
    esac
  done
}












[ "$1" == --lib ] && return 0; pdf_streams__"$@"; exit $?
