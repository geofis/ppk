#!/bin/bash

  if [[ $# -ne 6 ]]; then
    echo ""
    echo " Usage: solutions.sh solution_type conf_file_path base_position_type basepos1 basepos2 basepos3"
    echo " solution_type          (1:fix,2:float) [1]"
    echo " base_position_type     (l:latitude/longitude/height,r:ecef pos in m) [l]"
    echo ""
    exit 2
  fi

soltype=$1
conf=$2
basepostype=$3
basepos1=$4
basepos2=$5
basepos3=$6

# Convert RTK solutions to KML and extract observations from UBX to RINEX v 3.03 format
cd rover
for i in *.ubx; do pos2kml -q $soltype -o ${i/ubx*.ubx/rtk.kml} $i; convbin -v 3.03 -os -o ${i/-ubx*.ubx/.obs} $i; done
cd ..

# Generate PPK solutions
for i in rover/*.obs;\
  do
    rnx2rtkp -o ${i/.obs/-ppk.pos} -k $conf -$basepostype $basepos1 $basepos2 $basepos3 $i base/rinex_v211/merged.obs base/rinex_v303/*MN.rnx;\
    pos2kml -q $soltype ${i/.obs/-ppk.pos};\
done
