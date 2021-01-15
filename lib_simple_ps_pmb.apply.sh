#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function lib_simple_ps_pmb_apply () {
  [ "$#" == 0 ] || return 2$(
    echo "E: $FUNCNAME doesn't support CLI arguments" >&2)

  local SELFFILE="$(readlink -m "$0")"
  local SELFPATH="$(dirname "$SELFFILE")"
  local LIB_SRCFN="$SELFFILE"
  LIB_SRCFN="${LIB_SRCFN%.sh}"
  LIB_SRCFN="${LIB_SRCFN%.apply}"
  LIB_SRCFN="${LIB_SRCFN%.upd}"
  LIB_SRCFN="${LIB_SRCFN}.ps"
  local LIB_AUMARKS='%%autoupdate:LIB_SIMPLE_PS_PMB:§%%'
  local LIB_LINES='1{
      : wait
        /'"${LIB_AUMARKS//§/start}"'/b copy
        N;s~^.*\n~~;b wait
      : copy
      s~^%#scroll#$~~
    }'
  LIB_LINES="$(sed -re "$LIB_LINES" -- "$LIB_SRCFN")"
  local LIB_VER='5q;s~^\s*%%\{\s*"version":\s*"([^"]+)".*$~\1~p'
  LIB_VER="$(<<<"$LIB_LINES" sed -nre "$LIB_VER")"
  [ -n "$LIB_VER" ] || return 4$(echo 'E: cannot detect library version' >&2)
  local PKG_VER="$(PKJS="$SELFPATH/package.json" nodejs -p '
    require(process.env.PKJS).version')"
  [ -n "$PKG_VER" ] || return 4$(echo 'E: cannot detect package version' >&2)
  [ "$LIB_VER"  == "$PKG_VER" ] || echo "W: Library version (${LIB_VER%\
    }) differs from package version ($PKG_VER)" >&2
  local SED_INSERT_CMD='
    : copy
      /'"${LIB_AUMARKS//§/start}"'/{
        r /dev/stdin
        b skip_to_end_mark
      }
      /^\s*\/LIB_SIMPLE_PS_PMB \S* dict begin$/{
        # ^-- start marker of 0.0.x versions
        r /dev/stdin
        b skip_to_ancient_end_mark
      }
      p;n
    b copy
    : skip_to_ancient_end_mark
      n;/^\s*\/PMBPS \{.*\} def$/{n;b copy}
    b skip_to_end_mark
    : skip_to_end_mark
      n;/'"${LIB_AUMARKS//§/end}"'/{n;b copy}
    b skip_to_end_mark
    '

  local FN=
  local BFN=
  local TMP_BFN=
  for FN in *.ps; do
    [ -f "$FN" ] || continue
    [ -L "$FN" ] && continue
    BFN="$(basename "$FN" .ps)"
    case "$BFN" in
      lib_* ) continue;;
    esac
    echo -n "$FN: "
    ps2pdf "$FN" /dev/null || return $?$(
      echo "E: failed to render original $FN" >&2)
    TMP_BFN="tmp.upd-$$.$BFN"
    <<<"$LIB_LINES" sed -nrf <(echo "$SED_INSERT_CMD"
      ) -- "$FN" >"$TMP_BFN".ps || return $?
    grep -oPe "${LIB_AUMARKS//§/.*}" -- "$TMP_BFN".ps \
      | sort | uniq --repeated --count | grep . && return 4$(
      echo "E: found multiple markers of same type in $TMP_BFN.ps" >&2)
    diff -U 4 "$FN" "$TMP_BFN".ps >"$TMP_BFN".diff
    if [ -s "$TMP_BFN".diff ]; then
      ps2pdf "$TMP_BFN".ps /dev/null || return $?$(
        echo "E: failed to render $TMP_BFN.ps" >&2)
      mv --no-target-directory -- "$TMP_BFN".ps "$FN" || return $?$(
        echo "E: failed to mv $TMP_BFN.ps" >&2)
      echo 'updated.'
    else
      rm -- "$TMP_BFN".ps
      echo 'no changes.'
    fi
    rm -- "$TMP_BFN".diff
  done
}









[ "$1" == --lib ] && return 0; lib_simple_ps_pmb_apply "$@"; exit $?
