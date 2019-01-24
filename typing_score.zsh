#!/bin/zsh

cd $0:h || return 1

gnuplot ~ssri/admin/diskalert.gnuplot =(
    print -l 'plot "< ./typing_score.pm --output_format=gnuplot get_score_paragraph ../typing_score.txt" using 1:2 with lines '
) - 
