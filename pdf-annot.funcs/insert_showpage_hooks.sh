#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function enumerate_showpage_cmds () {
  local NL_OPT=(
    --body-numbering=a \
    --starting-line-number="${SRC_ANN[pages-from]}" \
    --number-format=ln \
    --number-width=1
    )
  grep -nxFe showpage -- "$@" | nl "${NL_OPT[@]}"
}


function insert_showpage_hooks () {
  local SHOWPAGE_HOOKS="$(enumerate_showpage_cmds "$TMP_BFN.orig.ps" \
    | csed -re 's!^\s*([0-9]+)\t([0-9]+|\
      ).*$!\2s~^.*$~/pg\1_annots showpage_with_annots~!')"
  # echo "D: SHOWPAGE_HOOKS: <$SHOWPAGE_HOOKS>" >&2
  csed -rf <(echo "1{/^%!PS/d}
    $SHOWPAGE_HOOKS") -- "$TMP_BFN.orig.ps" \
    >>"$TMP_BFN.out.ps" || return $?
}


return 0
