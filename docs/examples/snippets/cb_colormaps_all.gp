set terminal svg size 760,1280; set output 'cb_colormaps_all.svg'
# every named palette, by type: sequential, diverging, multi-sequential, cyclic
set multiplot layout 16,3
unset xtics; unset ytics; unset border; unset colorbox
set cbrange [0:255]
set title 'acton'; set palette acton; plot 'ramp.dat' matrix w image notitle
set title 'bamako'; set palette bamako; plot 'ramp.dat' matrix w image notitle
set title 'batlow'; set palette batlow; plot 'ramp.dat' matrix w image notitle
set title 'batlowK'; set palette batlowK; plot 'ramp.dat' matrix w image notitle
set title 'batlowW'; set palette batlowW; plot 'ramp.dat' matrix w image notitle
set title 'bilbao'; set palette bilbao; plot 'ramp.dat' matrix w image notitle
set title 'buda'; set palette buda; plot 'ramp.dat' matrix w image notitle
set title 'davos'; set palette davos; plot 'ramp.dat' matrix w image notitle
set title 'devon'; set palette devon; plot 'ramp.dat' matrix w image notitle
set title 'glasgow'; set palette glasgow; plot 'ramp.dat' matrix w image notitle
set title 'grayC'; set palette grayC; plot 'ramp.dat' matrix w image notitle
set title 'hawaii'; set palette hawaii; plot 'ramp.dat' matrix w image notitle
set title 'imola'; set palette imola; plot 'ramp.dat' matrix w image notitle
set title 'lajolla'; set palette lajolla; plot 'ramp.dat' matrix w image notitle
set title 'lapaz'; set palette lapaz; plot 'ramp.dat' matrix w image notitle
set title 'lipari'; set palette lipari; plot 'ramp.dat' matrix w image notitle
set title 'navia'; set palette navia; plot 'ramp.dat' matrix w image notitle
set title 'naviaW'; set palette naviaW; plot 'ramp.dat' matrix w image notitle
set title 'nuuk'; set palette nuuk; plot 'ramp.dat' matrix w image notitle
set title 'oslo'; set palette oslo; plot 'ramp.dat' matrix w image notitle
set title 'tokyo'; set palette tokyo; plot 'ramp.dat' matrix w image notitle
set title 'turku'; set palette turku; plot 'ramp.dat' matrix w image notitle
set title 'magma'; set palette magma; plot 'ramp.dat' matrix w image notitle
set title 'inferno'; set palette inferno; plot 'ramp.dat' matrix w image notitle
set title 'plasma'; set palette plasma; plot 'ramp.dat' matrix w image notitle
set title 'viridis'; set palette viridis; plot 'ramp.dat' matrix w image notitle
set title 'cividis'; set palette cividis; plot 'ramp.dat' matrix w image notitle
set title 'black_body' noenhanced; set palette black_body; plot 'ramp.dat' matrix w image notitle
set title 'bam'; set palette bam; plot 'ramp.dat' matrix w image notitle
set title 'berlin'; set palette berlin; plot 'ramp.dat' matrix w image notitle
set title 'broc'; set palette broc; plot 'ramp.dat' matrix w image notitle
set title 'cork'; set palette cork; plot 'ramp.dat' matrix w image notitle
set title 'lisbon'; set palette lisbon; plot 'ramp.dat' matrix w image notitle
set title 'managua'; set palette managua; plot 'ramp.dat' matrix w image notitle
set title 'roma'; set palette roma; plot 'ramp.dat' matrix w image notitle
set title 'tofino'; set palette tofino; plot 'ramp.dat' matrix w image notitle
set title 'vanimo'; set palette vanimo; plot 'ramp.dat' matrix w image notitle
set title 'vik'; set palette vik; plot 'ramp.dat' matrix w image notitle
set title 'bukavu'; set palette bukavu; plot 'ramp.dat' matrix w image notitle
set title 'fes'; set palette fes; plot 'ramp.dat' matrix w image notitle
set title 'oleron'; set palette oleron; plot 'ramp.dat' matrix w image notitle
set title 'bamO'; set palette bamO; plot 'ramp.dat' matrix w image notitle
set title 'brocO'; set palette brocO; plot 'ramp.dat' matrix w image notitle
set title 'corkO'; set palette corkO; plot 'ramp.dat' matrix w image notitle
set title 'romaO'; set palette romaO; plot 'ramp.dat' matrix w image notitle
set title 'vikO'; set palette vikO; plot 'ramp.dat' matrix w image notitle
unset multiplot
