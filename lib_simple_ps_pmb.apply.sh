#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
SELFFILE="$(readlink -m "$0")"; SELFPATH="$(dirname "$SELFFILE")"
SELFNAME="$(basename "$SELFFILE" .sh)"; INVOKED_AS="$(basename "$0" .sh)"


function lib_simple_ps_pmb_apply () {
  #cd "$SELFPATH" || return $?
  local LIB_SRCFN="$SELFFILE"
  LIB_SRCFN="${LIB_SRCFN%.sh}"
  LIB_SRCFN="${LIB_SRCFN%.apply}"
  LIB_SRCFN="${LIB_SRCFN}.ps"
  local LIB_START_RGX='^\s*\/LIB_SIMPLE_PS_PMB \S* dict begin$'
  local LIB_END_RGX='^\s*\/PMBPS \{.*\} def$'
  local LIB_MAXLN=9002
  local LIB_LINES="$(grep -Pe "$LIB_START_RGX" "$LIB_SRCFN" -A "$LIB_MAXLN")"
  local SED_INSERT_CMD='
    : copy
      /'"$LIB_START_RGX"'/{
        r /dev/stdin
        b skip_lib
      }
      p;n
    b copy
    : skip_lib
      n
      /'"$LIB_END_RGX"'/!b skip_lib
      n
    b copy'

  local FN=
  local BFN=
  local TMP_FN=
  for FN in *.ps; do
    [ -f "$FN" ] || continue
    [ -L "$FN" ] && continue
    BFN="$(basename "$FN" .ps)"
    case "$BFN" in
      lib_* ) continue;;
    esac
    echo -n "$FN: "
    TMP_FN="$BFN.upd-$$.tmp"
    <<<"$LIB_LINES" sed -nrf <(echo "$SED_INSERT_CMD"
      ) -- "$FN" >"$TMP_FN" || return $?
    # colordiff -sU 8 "$FN" "$TMP_FN"
    mv "$TMP_FN" "$FN" || return $?
    echo 'updated.'
  done

  return 0
}









[ "$1" == --lib ] && return 0; lib_simple_ps_pmb_apply "$@"; exit $?
