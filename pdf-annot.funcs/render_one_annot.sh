#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function render_one_annot () {
  local -A SRC_ANN=( [fn]="$1" ); shift
  local DEST_BFN="$(basename -- "${SRC_ANN[fn]}" .ann)"
  local TMP_BFN="tmp.$DEST_BFN.${PDFANNOT_PMB_DEBUG_BFN_PID:-$$}"
  wspnorm_one_annot || return $?

  local -A BGPDF=()
  scan_annot_meta || return $?
  decide_pages_range || return $?
  local DEST_PDF="$DEST_BFN.pdf"
  pdftops_one_annot || return $?
  begin_ps_output || return $?
  render_ann_code || return $?
  verify_ann_code || return $?
  insert_showpage_hooks || return $?
  ps2pdf "$TMP_BFN.out.ps" "$DEST_PDF" || return $?
  rm -- "${TMP_BFN:-/E/no/TMP_BFN/}."*
}


return 0
