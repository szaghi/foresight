set terminal svg size 640,300; set output 'cb_weekdates.svg'
# weekly counts keyed by ISO 8601 week dates ("2021-W05"), placed on a time axis
calendar(w) = weekdate_iso(int(w[1:4]), int(w[7:8]))
$WEEKLY << EOD
2020-W50 31
2020-W51 44
2020-W52 52
2020-W53 47
2021-W01 61
2021-W02 58
2021-W03 49
2021-W04 37
2021-W05 30
2021-W06 22
2021-W07 18
2021-W08 15
EOD
set xtics time format "%d %b\n%Y"; set ytics nomirror; set border 3; set key off
set title sprintf("week 1 of 2021 starts on %s (tm\\_week of 1 January 2021: %d)", \
                  strftime("%a %d %b", weekdate_iso(2021, 1)), tm_week(strptime("%Y-%m-%d", "2021-01-01"), 0))
plot $WEEKLY using (calendar(strcol(1))):2 with linespoints pt 7 lw 2
