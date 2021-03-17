#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function find_one_ann_meta_hint () {
  local HINT_NAME="$1"; shift
  local DEST_DICT="$1"; shift
  local DEST_SLOT="$1"; shift
  [ "$DEST_SLOT" == '=' ] && DEST_SLOT="$HINT_NAME"
  local VAL="$(grep -Pe "^%:$HINT_NAME=" -m 1 -- "$TMP_BFN.wspnorm.ann")"
  VAL="${VAL#*=}"
  [ "$#:$VAL" == 0: ] && return 2$(
    echo "E: unable to find %:$HINT_NAME= in ${SRC_ANN[fn]}" >&2)
  eval "$DEST_DICT"'["$DEST_SLOT"]="$VAL"'
}


function scan_annot_meta () {
  find_one_ann_meta_hint src-pdf BGPDF fn || return $?
  [ -f "${BGPDF[fn]}" ] || return 2$(echo 'E: unable to find background PDF' \
    "'${BGPDF[fn]}' for ${SRC_ANN[fn]}" >&2)
  BGPDF[meta]="$(LANG=C pdfinfo -- "${BGPDF[fn]}" | csed -re '
    s~:\s+~:~')"
  BGPDF[pgcnt]="$(<<<"${BGPDF[meta]}" csed -nre 's~^[Pp]ages:~~p')"
  [ "${BGPDF[pgcnt]:-0}" -gt 0 ] || return 2$(echo 'E: unable to count' \
    "pages of background PDF '${BGPDF[fn]}' for ${SRC_ANN[fn]}" >&2)
  find_one_ann_meta_hint pages-range SRC_ANN = '' || return $?
}


return 0
