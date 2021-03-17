#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function render_annot_files () {
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
}


return 0
