#!/bin/sed -nrf
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
    s~^.*$~} bind def\n\n(annots: unsupported: &) FAIL {~
    b ann_next
    }
  /^\s*(def)(\s|$)/b cmd_line
  /^\s*(<:id:>)\s+(<:id:>)\s+(<:id:>\s*=\s*|)(\(|\$)/b text_line
  /^\s*[A-Za-z]<:id:>(\s|$)/b cmd_line
  s~^%:[a-z\-]+=.*$~~
  s~^\s*\#.*$~~
  s~^[^%]~%?! &~
: ann_next
  1s~^~\n/prepare_annots \{\n~
  $s~$~\n\} bind def\n~
  # s~\n{2,}~\n~g
  /\S/p
  n
b ann_line

: begin_page
  s~^.*=([0-9]+)$~/pg\1_annots {\n  /annot_pgnr \1 def~
  i} bind def
  i
  a\  prepare_annots
  a\  annot_pgnr 2 mod 0 eq { pghead_even_annots } { pghead_odd_annots } ifelse
  a\  pghead_each_annots
b ann_next

: text_line
  /\)\.\.$/{
    N
    s~\)\.\.\n\s*\(~~
    b text_line
  }
  s~^(\s*(\S+\s+){2})[^=\(]*=\s*\$?~\1~
  s~$~\r~
  s~\s(\(\s*\?\s*|<\?>)\)\s*$~& annot_unsure~
  s~\r~ /print_mxty PMBPS~
b ann_next

: cmd_line
  s~^\s*(def)\s+~&/~
  s~^(\s*)(crossout|rgbrect|unsure)(\s+|$)~\1annot_\2\3~
  s~^(\s*)(\S+)(\s+|$)(.*)$~\1\4\3\2~
b ann_next
