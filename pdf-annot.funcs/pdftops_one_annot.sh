#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function pdftops_one_annot () {
  echo "annotating page ${SRC_ANN[pages-from]}..${SRC_ANN[pages-upto]}" \
    "of ${BGPDF[pgcnt]} from ${BGPDF[fn]}" \
    "with ${SRC_ANN[fn]} -> $TMP_BFN.out.ps -> $DEST_PDF:"
  local PDF2PS=(
    pdftops
    -f "${SRC_ANN[pages-from]}"
    -l "${SRC_ANN[pages-upto]}"
    -level3
    -origpagesizes
    "${BGPDF[fn]}" "$TMP_BFN.orig.ps"
    )
  "${PDF2PS[@]}" 2>&1 | csed -re '
    /^Error [^:]+: No current point in closepath$/d
    s~^~pdftops: ~' >&2
  local RETVAL="${PIPESTATUS[0]}"
  [ "$RETVAL" == 0 ] || return 4$(echo "E: pdftops rv=$RETVAL" >&2)
}


return 0
