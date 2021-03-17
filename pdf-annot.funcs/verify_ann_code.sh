#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function verify_ann_code () {
  if grep -HnPe '^\s*%\?\!' "$TMP_BFN.out.ps"; then
    echo "E: Found unsupported annotations (see above)." >&2
    return 2
  fi
  # return 2
  # nl -ba "$TMP_BFN.out.ps"
}


return 0
