#!/bin/bash

year=$1

# Rinex v 2.11
for i in base/rinex_v211/*.zip; do unzip $i -d base/rinex_v211 *${year}O; done
teqc -phc base/rinex_v211/*${year}O > base/rinex_v211/merged.obs
rm base/rinex_v211/*${year}O

# Rinex v 3.03
unzip base/rinex_v303/*.zip -d base/rinex_v303/ *MN.rnx *.${year}P
