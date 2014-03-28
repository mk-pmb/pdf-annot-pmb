#!/bin/sed -nrf
# -*- coding: UTF-8, tab-width: 2 -*-

^s~<:id:>~[A-Za-z0-9_\\.\\-]+~g

: ann_line
  /^\s*%:pg=([0-9]+)$/b begin_page
  /^\s*(<:id:>)\s+(<:id:>)\s+(<:id:>=|)\(/b text_line
  /^\s*[a-z0-9_]+\s+/b cmd_line
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
  s~^.*=([0-9]+)$~} bind def\n\n/pg\1_annots {~
b ann_next

: text_line
  /\)\.\.$/{
    N
    s~\)\.\.\n\s*\(~~
    b text_line
  }
  s~^(\s*(\S+\s+){2})[^=\(]*=~\1~
  s~$~ /print_mxty PMBPS~
b ann_next

: cmd_line
  s~^\s*(def)\s+~&/~
  s~^(\s*)(crossout|rgbrect)(\s+)~\1annot_\2\3~
  s~^(\s*)(\S+)(\s+)(.*)$~\1\4\3\2~
b ann_next
