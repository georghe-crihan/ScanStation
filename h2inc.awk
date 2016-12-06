#!/usr/bin/awk -f

/#define/ {
  if ($3!="")
    printf("%s equ %s\n", $2, $3);
}
