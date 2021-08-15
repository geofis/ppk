#!/bin/bash

# Create directories
mkdir -p base/{real_time,rinex_v211,rinex_v303}
mkdir -p rover

if ! compgen -G "*.ubx" > /dev/null
then
  echo ""
  echo " Couldn't find the rover files (*.ubx) in this directory."
  echo " Place the rover files in this directory and run again prepare.sh,"
  echo " or place then in the 'rover' directory."
  echo ""
else
  mv -i *.ubx rover
  echo ""
  echo " Now, copy the files of the base station."
  echo ""
  echo " For this, download the base data from the base station repo, download and copy"
  echo ' to "base/rinex_v211" directory, the "Observables" (no ephemeris) files '
  echo ' in RINEX v 2.11 of a time-range encompassing the time of the data collected,'
  echo ' using the dataset of "Continuous 60 Min." recording with '
  echo ' Measurements 1 Sec. Positions 1 Min. (B directory).'
  echo ""
  echo ' Also, from the base station repo, download "Observables and combined ephemeris"'
  echo ' files in RINEX v 3.03 format of the entire day collection, using the dataset of'
  echo ' "Continuous 1440 Min." recording with "Measurements 15 Sec. Positions'
  echo ' 5 Min. (DEFAULT directory)".'
  echo ""
fi

if ! compgen -G "*.rtcm3" > /dev/null
then
  echo ""
  echo " Couldn't find the base RTCM correction files (*.rtcm3). Place the RTCM"
  echo ' correction files in this directory and run again prepare.sh, or place'
  echo ' then in the "base/real_time" directory.'
  echo ""
else
  mv -i *.rtcm3 base/real_time
fi
