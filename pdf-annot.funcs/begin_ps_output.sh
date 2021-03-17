#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function begin_ps_output () {
  head --lines=1 -- "$TMP_BFN.orig.ps" >"$TMP_BFN.out.ps" || return $?
  local LIST=(
    lib_simple_ps_pmb
    annot.inc
    )
  local ITEM=
  for ITEM in "${LIST[@]}"; do
    csed -re '1{/^%!PS/d}' -- "$SELFPATH/$ITEM.ps" \
      >>"$TMP_BFN.out.ps" || return $?
  done
}


return 0
