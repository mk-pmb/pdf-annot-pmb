#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function pdfannot () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFFILE="$(readlink -m -- "$BASH_SOURCE")"
  local SELFPATH="$(dirname -- "$SELFFILE")"
  local SELFNAME="$(basename -- "$SELFFILE" .sh)"
  local ITEM=
  for ITEM in "$SELFPATH"/pdf-annot.funcs/*.sh; do
    source -- "$ITEM" --lib || return $?
  done

  local -A CFG=(
    [task]=   # might be set by parse_cli
    [repeat]=once
    )
  local FILES=()
  parse_cli "$@" || return $?
  [ -z "${CFG[task]}" ] || "${CFG[task]}" || return $?
}


pdfannot "$@"; exit $?
