#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function pdfannot () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFFILE="$(readlink -m -- "$BASH_SOURCE")"
  local SELFPATH="$(dirname -- "$SELFFILE")"
  local SELFNAME="$(basename -- "$SELFFILE" .sh)"

  local -A CFG=(
    [task]=   # might be set by parse_cli
    [repeat]=once
    )
  local FILES=()
  parse_cli "$@" || return $?
  [ -z "${CFG[task]}" ] || "${CFG[task]}" || return $?
}


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
        CFG[pages]="$1"; shift;;
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


function csed () { LANG=C sed "$@"; }


function render_one_annot () {
  local -A SRC_ANN=( [fn]="$1" ); shift
  local DEST_BFN="$(basename -- "${SRC_ANN[fn]}" .ann)"
  local TMP_BFN="tmp.$DEST_BFN.${PDFANNOT_PMB_DEBUG_BFN_PID:-$$}"
  csed -re '
    /^\s*(#|$)/d
    s~\r$~~
    ' -- "${SRC_ANN[fn]}" >"$TMP_BFN.wspnorm.ann" || return $?
  local PGNUM="${CFG[pages]}"

  local -A BGPDF=()
  BGPDF[fn]="$(grep -Pe '^%:src-pdf=' -m 1 -- "$TMP_BFN.wspnorm.ann" \
    | cut -d = -sf 2-)"
  [ -n "${BGPDF[fn]}" ] || return 2$(
    echo "E: unable to find %:src-pdf= in ${SRC_ANN[fn]}" >&2)
  [ -f "${BGPDF[fn]}" ] || return 2$(echo 'E: unable to find background PDF' \
    "'${BGPDF[fn]}' for ${SRC_ANN[fn]}" >&2)
  BGPDF[meta]="$(LANG=C pdfinfo -- "${BGPDF[fn]}" | csed -re '
    s~:\s+~:~')"
  BGPDF[pgcnt]="$(<<<"${BGPDF[meta]}" csed -nre 's~^[Pp]ages:~~p')"
  [ "${BGPDF[pgcnt]:-0}" -gt 0 ] || return 2$(echo 'E: unable to count' \
    "pages of background PDF '${BGPDF[fn]}' for ${SRC_ANN[fn]}" >&2)

  local PGNUM_ZF="$PGNUM"
  while [ "${#PGNUM_ZF}" -lt "${#BGPDF[pgcnt]}" ]; do
    PGNUM_ZF="0$PGNUM_ZF"
  done
  [ -n "$PGNUM" ] && DEST_BFN+=".$PGNUM_ZF"
  local DEST_PDF="$DEST_BFN.pdf"

  echo "annotating page ${PGNUM:-all} of ${BGPDF[pgcnt]} in ${BGPDF[fn]}" \
    "with ${SRC_ANN[fn]} -> $TMP_BFN.out.ps -> $DEST_PDF:"

  local PDF2PS=( pdftops )
  [ -n "$PGNUM" ] && PDF2PS+=( -f "$PGNUM" -l "$PGNUM" )
  PDF2PS+=( -level3 )
  PDF2PS+=( -origpagesizes )
  PDF2PS+=( "${BGPDF[fn]}" "$TMP_BFN.orig.ps" )
  "${PDF2PS[@]}" 2>&1 | csed -re '
    /^Error [^:]+: No current point in closepath$/d
    s~^~pdftops: ~' >&2
  local RETVAL="${PIPESTATUS[0]}"
  [ "$RETVAL" == 0 ] || return 4$(echo "E: pdftops rv=$RETVAL" >&2)

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

  render_ann_code || return $?
  if grep -HnPe '^\s*%\?\!' "$TMP_BFN.out.ps"; then
    echo "E: Found unsupported annotations (see above)." >&2
    return 2
  fi
  # return 2
  # nl -ba "$TMP_BFN.out.ps"

  local SHOWPAGE_HOOKS="$(enumerate_showpage_cmds "$TMP_BFN.orig.ps" \
    | csed -re 's!^\s*([0-9]+)\t([0-9]+|\
      ).*$!\2s~^.*$~/pg\1_annots showpage_with_annots~!')"
  # echo "D: SHOWPAGE_HOOKS: <$SHOWPAGE_HOOKS>" >&2
  csed -rf <(echo "1{/^%!PS/d}
    $SHOWPAGE_HOOKS") -- "$TMP_BFN.orig.ps" \
    >>"$TMP_BFN.out.ps" || return $?
  ps2pdf "$TMP_BFN.out.ps" "$DEST_PDF" || return $?

  rm -- "${TMP_BFN:-/E/no/TMP_BFN/}."*
}


function enumerate_showpage_cmds () {
  local NL_OPT=(
    --body-numbering=a \
    --starting-line-number="${PGNUM:-1}" \
    --number-format=ln \
    --number-width=1
    )
  grep -nxFe showpage -- "$@" | nl "${NL_OPT[@]}"
}


function metased_unpack_rules () {
  local METASED_FILE="$1"
  case "$METASED_FILE" in
    :* ) METASED_FILE="$SELFPATH/${METASED_FILE#:}.sed";;
  esac
  local META_TRANSFORMS="$(csed -nre 's~^(\s*)\^~\1~p
    ' -- "$METASED_FILE")"
  csed -re '/^\s*\^/d;'"$META_TRANSFORMS" -- "$METASED_FILE"
}


function render_ann_code () {
  [ -n "$TMP_BFN" ] || return 3$(echo "E: no TMP_BFN" >&2)
  local REND="$TMP_BFN.ann-rend.ps"
  csed -nrf <(metased_unpack_rules :parse-annot
    ) -- "$TMP_BFN.wspnorm.ann" >"$REND" || return 3$(
    echo "E: meta sed in $FUNCNAME failed." >&2)

  sed -rf <(sedrules_ann_include_lines "$REND") -i -- "$REND" || return $?$(
    echo "E: failed to insert files for include lines" >&2)

  cat -- "$REND" >>"$TMP_BFN.out.ps" || return $?
}


function sedrules_ann_include_lines () {
  grep -hnFe '%?!' -- "$1" | csed -nrf <(echo '
    s~^([0-9]+):%\?\!\s+%:include=(.*)$~\1{s!^\\S+\\s+!% !;r \2\n    }~p')
}























pdfannot "$@"; exit $?
