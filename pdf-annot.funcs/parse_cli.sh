#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function parse_cli () {
  local OPT=
  while [ "$#" -gt 0 ]; do
    OPT="$1"; shift
    case "$OPT" in
      '' ) ;;
      -- ) FILES+=( "$@" ); break;;
      --debug ) cli_debug "$@"; return $?;;
      -w | --watch | \
      -m | --monitor )
        CFG[repeat]=watch;;
      -p | --pages )
        CFG[pages-range]="$1"; shift;;
      --*=* )
        OPT="${OPT#--}"
        CFG["${OPT%%=*}"]="${OPT#*=}";;
      --help | \
      -* )
        local -fp "${FUNCNAME[0]}" | guess_bash_script_config_opts-pmb
        [ "${OPT//-/}" == help ] && return 0
        echo "E: $0: unsupported option: $OPT" >&2; return 1;;
      * ) FILES+=( "$OPT" );;
    esac
  done
  [ -n "${CFG[task]}" ] || CFG[task]='render_annot_files'
}


function cli_debug () {
  if [ "$(type -t "$1")" == 'function' ]; then
    "$@"; return $?
  fi
  OPT="$(declare -p)"
  <<<"$OPT" grep -Pe '^declare\s+\S+\s+'"$1=" -A "${#OPT}" \
    | grep -Pe '^declare\s+\S+\s+\S+=' -B "${#OPT}" -m 2 | sed -re '$d'
  [ "${PIPESTATUS[0]}" == 0 ] && return 0
  echo "E: neither a function nor declared: $1" >&2
  return 3
}


return 0
