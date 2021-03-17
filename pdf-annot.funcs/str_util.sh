#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function csed () { LANG=C sed "$@"; }


function wspnorm_one_annot () {
  csed -rf <(echo '
    /^\s*(#|$)/d
    s~\r$~~
    ') -- "${SRC_ANN[fn]}" >"$TMP_BFN.wspnorm.ann" || return $?
}


return 0
