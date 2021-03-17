#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function decide_pages_range () {
  local N="${BGPDF[pgcnt]:-0}"  # total Number of pages
  local F=1     # From
  local T="$N"  # To
  local K='pages-range'     # config Key
  local A="${SRC_ANN[$K]}"  # ann restriction
  local C="${CFG[$K]}"      # config restriction
  local R=  # Restriction
  local B=  # Bound
  for R in "$A" "$C"; do
    # echo -n "D: range: $F..$T | '$R' = "
    B="${R%-*}" # from
    [ "${B:-0}" -gt "$F" ] && F="$B"
    # echo -n "'$B'.."
    B="${R#*-}" # upto
    [ "${B:-0}" -ge 1 ] && [ "$B" -lt "$T" ] && T="$B"
    # echo "'$B' -> $F..$T"
  done
  [ -z "${CFG[pages-range]}" ] || printf -v DEST_BFN '%s.p%0*d-%0*d' \
    "$DEST_BFN" "${#N}" "$F" "${#N}" "$T"
  SRC_ANN[pages-from]="$F"
  SRC_ANN[pages-upto]="$T"
  [ "$T" -ge "$F" ] && return 0
  echo "D: Page number restrictions: pdf='1-$N' ann='$A' config='$C'"
  echo "E: Found no page numbers in range $F..$T." >&2
  return 4
}


return 0
