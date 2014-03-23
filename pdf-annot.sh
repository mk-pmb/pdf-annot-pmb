#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
SELFFILE="$(readlink -m "$0")"; SELFPATH="$(dirname "$SELFFILE")"
SELFNAME="$(basename "$SELFFILE" .sh)"


function main () {
  # cd "$SELFPATH" || return $?
  local PARSE_ANN="$(metased_unpack_rules "$SELFPATH"/parse-annot.sed)"
  local -A CFG
  CFG[repeat]=once
  local FILES=()
  local OPT=
  while [ "$#" -gt 0 ]; do
    OPT="$1"; shift
    case "$OPT" in
      '' ) ;;
      -- ) FILES+=( "$@" ); break;;
      --debug )
        if [ "$(type -t "$1")" == 'function' ]; then
          "$@"; return $?
        fi
        OPT="$(declare -p)"
        <<<"$OPT" grep -Pe '^declare\s+\S+\s+'"$1=" -A "${#OPT}" \
          | grep -Pe '^declare\s+\S+\s+\S+=' -B "${#OPT}" -m 2 | sed -re '$d'
        [ "${PIPESTATUS[0]}" == 0 ] && return 0
        echo "E: neither a function nor declared: $1" >&2
        return 3;;
      -w | -watch | \
      -m | --monitor )
        CFG[repeat]=watch;;
      -p | --pages )
        CFG[pages]="$1"; shift;;
      --*=* )
        OPT="${OPT#--}"
        CFG["${OPT%%=*}"]="${OPT#*=}";;
      -* ) return 1$(echo "E: $0: unsupported option: $OPT" >&2);;
      * ) FILES+=( "$OPT" );;
    esac
  done

  local FN=
  for FN in "${FILES[@]}"; do
    render_one_annot "$FN" || return $?
  done

  SECONDS=0
  while [ "${CFG[repeat]}" == watch ]; do
    echo "$(date +%T) (+${SECONDS}s) watching for file changes..."
    SECONDS=0
    FN="$(inotifywait  --quiet --timefmt='%T' --format '%T=%w' \
      --event close_write "${FILES[@]}")"
    [ -n "$FN" ] || return 0
    echo -n "${FN%%=*} "
    FN="${FN#*=}"
    echo "(+${SECONDS}s) $FN"
    SECONDS=0
    render_one_annot "$FN" || return $?
  done

  return 0
}


function render_one_annot () {
  local -A SRC_ANN
  SRC_ANN[fn]="$1"; shift
  SRC_ANN[code]="$(sed "${SRC_ANN[fn]}" -re '
    /^\s*(#|$)/d
    s~\r~~
    ')"
  local PGNUM="${CFG[pages]}"

  local -A BGPDF
  BGPDF[fn]="$(<<<"${SRC_ANN[code]}" grep -Pe '^%:src-pdf=' -m 1 \
    | cut -d = -sf 2-)"
  [ -n "${BGPDF[fn]}" ] || return 2$(
    echo "E: unable to find %:src-pdf= in ${SRC_ANN[fn]}" >&2)
  [ -f "${BGPDF[fn]}" ] || return 2$(echo 'E: unable to find background PDF' \
    "'${BGPDF[fn]}' for ${SRC_ANN[fn]}" >&2)
  BGPDF[meta]="$(LANG=C pdfinfo "${BGPDF[fn]}" | sed -re 's~:\s+~:~')"
  BGPDF[pgcnt]="$(<<<"${BGPDF[meta]}" sed -nre 's~^[Pp]ages:~~p')"
  [ "${BGPDF[pgcnt]:-0}" -gt 0 ] || return 2$(echo 'E: unable to count' \
    "pages of background PDF '${BGPDF[fn]}' for ${SRC_ANN[fn]}" >&2)

  local DEST_BFN="$(basename "${SRC_ANN[fn]}" .ann)"
  local PGNUM_ZF="$PGNUM"
  while [ "${#PGNUM_ZF}" -lt "${#BGPDF[pgcnt]}" ]; do
    PGNUM_ZF="0$PGNUM_ZF"
  done
  [ -n "$PGNUM" ] && DEST_BFN+=".$PGNUM_ZF"
  local DEST_PS="${DEST_BFN}.ps"
  local DEST_TMP="${DEST_BFN}.tmp"
  local DEST_PDF="${DEST_BFN}.pdf"

  echo "annotating page ${PGNUM:-all} of ${BGPDF[pgcnt]} in ${BGPDF[fn]}" \
    "with ${SRC_ANN[fn]} -> $DEST_PS -> $DEST_PDF:"

  local PDF2PS=( pdftops )
  [ -n "$PGNUM" ] && PDF2PS+=( -f "$PGNUM" -l "$PGNUM" )
  PDF2PS+=( -level3 )
  PDF2PS+=( -origpagesizes )
  PDF2PS+=( "${BGPDF[fn]}" "$DEST_TMP" )
  "${PDF2PS[@]}" 2>&1 | sed -re '
    /^Error [^:]+: No current point in closepath$/d
    s~^~pdftops: ~' >&2
  local RETVAL="${PIPESTATUS[0]}"
  [ "$RETVAL" == 0 ] || return 4$(echo "E: pdftops rv=$RETVAL" >&2)

  head -n 1 "$DEST_TMP" >"$DEST_PS" || return $?
  local ITEM=
  for ITEM in lib_simple_ps_pmb annot.inc; do
    sed -re '1{/^%!PS/d}' "$SELFPATH/$ITEM.ps" >>"$DEST_PS" || return $?
  done

  SRC_ANN[annot-pages]="$(<<<"${SRC_ANN[code]}" sed -nre '
    s~^\s*%:pg=([0-9]+)$~ \1\t~p')
    <:>"
  # echo "pages with annots: ${SRC_ANN[annot-pages]}" | tr '\t' '^' >&2
  <<<"${SRC_ANN[code]}" render_ann_code >>"$DEST_PS" || return $?
  # nl -ba "$DEST_PS"

  sed "$DEST_TMP" -re "
    1d
    $(grep -nxFe showpage "$DEST_TMP" | nl -ba -v"${PGNUM:-1}" -w 12 \
      | grep -Fe "${SRC_ANN[annot-pages]}" | sed -re 's!^\s*([0-9]+)\t([0-9]+|\
        ).*$!\2s~^.*$~/pg\1_annots showpage_with_annots~!')
    " >>"$DEST_PS" || return $?
  ps2pdf "$DEST_PS" || return $?
  for ITEM in "$DEST_TMP" "$DEST_PS" "$DEST_BFN".tmp.{pdf,ps}; do
    [ -f "$ITEM" ] && rm "$ITEM"
  done
  return 0
}


function metased_unpack_rules () {
  local METASED_FILE="$1"
  local META_TRANSFORMS="$(sed -nre 's~^(\s*)\^~\1~p' "$METASED_FILE")"
  sed -re '/^\s*\^/d;'"$META_TRANSFORMS" "$METASED_FILE"
}


function render_ann_code () {
  sed -nre "$PARSE_ANN"
}




















main "$@"; exit $?
