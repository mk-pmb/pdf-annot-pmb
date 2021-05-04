#!metased -nrf
# -*- coding: UTF-8, tab-width: 2 -*-

^s~<:id:>~[A-Za-z0-9_\\.\\-]+~g

: ann_line
  /^\s*%"/{s~^\s*%"~~;b ann_next}
  /^\s*%:pg=([0-9]+)$/b begin_page
  /^\s*%:pg=(even|odd|each)$/{
    s~^.*=([a-z]+)$~} bind def\n\n/pghead_\1_annots {~
    b ann_next
    }
  /^\s*%:pg=/{
    s~^.*$~} bind def\n\
    (annots: unsupported: &) FAIL {~
    b ann_next
    }
  /^\s*(def|set[a-z]+)(\s|$)/b cmd_line
  /^\s*(<:id:>)\s+(<:id:>)\s+(<:id:>\s*=\s*|)((%<:id:>|)\(|\$)/b text_line
  /^\s*[A-Za-z]<:id:>(\s|$)/b cmd_line
  s~^%:[a-z\-]+=.*$~~
  s~^\s*\#.*$~~
  s~^[^%]~%?! &~
: ann_next
  1s~^~\
    /annot_pgnr 0 def\n\
    /prepare_annots \{\
      annot_pgnr 2 mod 0 eq { pghead_even_annots } { pghead_odd_annots } ifelse\
    ~
  ${
    a\} bind def
    a\%% ENDOF annots
    a
  }
  # s~\n{2,}~\n~g
  /\S/p
  n
b ann_line

: begin_page
  s~^.*=([0-9]+)$~/pg\1_annots {\
    /annot_pgnr \1 def\
    ~
  i\} bind def
  i
  a\  prepare_annots
  a\  pghead_each_annots
b ann_next

: text_line
  /\)\.\.$/{
    N
    s~\)\.\.\n\s*\(~~       # merge multi-line strings
    b text_line
  }
  s~^(\s*(\S+\s+){2})[^=\(]*=\s*\$?~\1~
  s~^(\s*(\S+\s+){2})%(<:id:>)\(~%\a \3 \1(~
  /^%\a/b ann_next
  s~$~\r~
  s~\s(\(\s*\?\s*|<\?>)\)\s*$~& annot_unsure~
  s~\r~ /print_mxty PMBPS~
b ann_next

: cmd_line
  s~^\s*(def)\s+~&/~
  s~^\s*(setblack)\s+([0-9.]+)~\2 /\1 PMBPS~
  s~^\s*(setgr[ae]y)\s~() == (\1: try setblack) == () == \1 ~
  s~^(\s*)(crossout|rgbrect|unsure|textblock)(\s+|$)~\1annot_\2\3~
  /\[$/{
    : cmd_line__read_more_array_lines
    /\]$/!{N; b cmd_line__read_more_array_lines}
    # s~\n\s*~ ~g
  }
  # put the command behind the args:
  s~^($=indent|\s*)($=cmd|[a-zA-Z_0-9]+)($=argsep\
    |\s+|$)($=args|.*)$~\1\4\3\2~
b ann_next



















: scroll
