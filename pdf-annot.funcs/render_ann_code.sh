#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function metased_unpack_rules () {
  local METASED_FILE="$1"
  case "$METASED_FILE" in
    :* ) METASED_FILE="$SELFPATH/${METASED_FILE#:}.sed";;
  esac
  local META_TRANSFORMS="$(csed -nre 's~^(\s*)\^~\1~p
    ' -- "$METASED_FILE")"
  csed -re '/^\s*\^/d;'"$META_TRANSFORMS" -- "$METASED_FILE"
}


function preg_quote () { csed -re 's~[^A-Za-z0-9_]~\\&~g' -- "$@"; }


function sedrules_ann_include_lines () {
  local HOME_PQ="$(preg_quote <<<"$HOME")"
  grep -hnFe '%?!' -- "$1" | csed -nrf <(echo '
    s~^([0-9]+):%\?\!\s+%:include=(.*)$~\1{s!^\\S+\\s+!% !\
      r \2\n    }~p
    ') | csed -rf <(echo '
    s!^(\s*r +)~/!\1'"$HOME_PQ"'/!
    ')
}


function render_ann_code () {
  [ -n "$TMP_BFN" ] || return 3$(echo "E: no TMP_BFN" >&2)
  local REND="$TMP_BFN.ann-rend.ps"
  csed -nrf <(metased_unpack_rules :parse-annot
    ) -- "$TMP_BFN.wspnorm.ann" >"$REND" || return 3$(
    echo "E: meta sed in $FUNCNAME failed." >&2)

  sed -rf <(sedrules_ann_include_lines "$REND") -i -- "$REND" || return $?$(
    echo "E: failed to insert files for include lines" >&2)

  cat -- "$REND" >>"$TMP_BFN.out.ps" || return $?
}


return 0
