#!/bin/bash

#  author: José Ramón Martínez Batlle, March, 7, 2022
#  GitHub: geofis
#  Twitter: @geografiard

################################################################################
# Help function                                                                #
################################################################################
Help()
{
   # Display Help
   echo

   echo "    ppk.sh is a wrapper function of the RTKLIB Demo5 rnx2rtkp app, that performs"
   echo "    post-processing analysis from base and rover data. The user must provide a"
   echo "    configuration file, base and rover observation files (RINEX v3, ZIP "
   echo "    containing UBX files or UBX files directly) and at least one navigation"
   echo "    messages file. Optionally, antenna calibration data may be provided."
   echo "    Requires RTKLIB Demo5 installed on the computer."
   echo
   echo "    Syntax: ppk [-iftHsh] -c configuration file -r rover file -b base file [-n nav file]"
   echo "    Options:"
   echo "    i     Time interval in seconds for computing solutions [15]"
   echo "    f     Antenna calibration file"
   echo "    t     Antenna type"
   echo "    H     Antenna height in meters, i.e. pole height"
   echo "    s     Output solution format (llh;enu;xyz;nmea) [llh]"
   echo "    o     Output solution static (all;single) [single]"
   echo "    h     Display help"
   echo
   echo "    Example of use with RINEX files"
   echo "    ./ppk.sh -i 15 -c conf/ppk.conf -r example-rinex/rover/2022-02-25_13-26-06_GNSS-1.obs \\"
   echo "    -b example-rinex/base/2022-02-25_00-00-00_GNSS-1.obs \\"
   echo "    -n example-rinex/base/2022-02-25_00-00-00_GNSS-1.nav \\"
   echo "    -f ant/AS-ANT2BCAL.atx -t AS-ANT2BCAL -H 2"
   echo
   echo "    Example with ZIP files with ENU as output solution format"
   echo "    ./ppk.sh -i 15 -c conf/ppk.conf -r example-zip/2022-02-25_13-26-06_GNSS-1.ubx.zip \\"
   echo "    -b example-zip/2022-02-25_00-00-00_GNSS-1.ubx.zip \\"
   echo "    -f ant/AS-ANT2BCAL.atx -t AS-ANT2BCAL  -H 2 -s enu"
   echo
   echo "    Example of use with UBX files with ALL solutions enumerated exhaustively"
   echo "    ./ppk.sh -i 15 -c conf/ppk.conf -r example-ubx/rover/2022-02-25_13-26-06_GNSS-1.ubx \\"
   echo "    -b example-ubx/base/2022-02-25_00-00-00_GNSS-1.ubx \\"
   echo "    -f ant/AS-ANT2BCAL.atx -t AS-ANT2BCAL -H 2 -o all"
   echo
   exit
}

################################################################################
# Main program                                                                 #
################################################################################

# Timestamp
timestamp=`date +'%Y%m%dT%H%M%S'`

# Log file var
log_filename="errors-$timestamp.log"

# Manage arguments with flags
while getopts ":i:c:r:b:n:f:t:H:s:o:h" opt; do
    case $opt in
        i) time_interval="$OPTARG"
        ;;
        c) conf_file="$OPTARG"
        ;;
        r) rover_file="$OPTARG"
        ;;
        b) base_file="$OPTARG"
        ;;
        n) nav_file="$OPTARG"
        ;;
        f) ant_file="$OPTARG"
        ;;
        t) ant_type="$OPTARG"
        ;;
        H) ant_height="$OPTARG"
        ;;
        s) out_solformat="$OPTARG"
        ;;
        o) out_solstatic="$OPTARG"
        ;;
        h) Help
        ;;
        \?) echo "Invalid option -$OPTARG" 2>&1 | tee -a $log_filename
        exit;;
    esac
done
shift $((OPTIND -1))

# Check file exists
check_file_exists () {
  local file=$1
  if [ ! -f $file ]; then
   echo -e "\n  File $file not found" 2>&1 | tee -a $log_filename
   exit 0
  fi
}

# Arguments
if [ -z $time_interval ]; then
  echo "  Time interval: argument not provided, using default (15 seconds)"
  time_interval=15
  else echo "  Time interval: $time_interval seconds"
fi
if [ -z $conf_file ]; then
  echo "  Configuration file: required argument not provided. Exiting" 2>&1 | tee -a $log_filename
  exit 1
  else
  check_file_exists $conf_file
  echo "  Configuration file: $conf_file"
fi
if [ -z $rover_file ]; then
  echo "  Rover source file: required argument not provided. Exiting" 2>&1 | tee -a $log_filename
  exit 1
  else
  check_file_exists $rover_file
  echo "  Rover source file: $rover_file"
fi
if [ -z $base_file ]; then
  echo "  Base source file: required argument not provided. Exiting" 2>&1 | tee -a $log_filename
  exit 1
  else
  check_file_exists $base_file
  echo "  Base source file: $base_file"
fi
if [ -z $nav_file ]; then
  echo "  Navigation file: argument not provided, will try finding one within ZIP or UBX files"
  else
  check_file_exists $nav_file
  echo "  Navigation file: $nav_file"
fi
if [ -z $ant_file ]; then
  echo "  Antenna calibration file: argument not provided, using default"
  else
  check_file_exists $ant_file
  echo "  Antenna calibration file: $ant_file"
fi
if [ -z $ant_type ]; then
  echo "  Antenna type: argument not provided, using default"
  else echo "  Antenna type: $ant_type"
fi
if [ -z $ant_height ]; then
  echo "  Antenna height (i.e. pole height): none provided"
  else echo "  Antenna height, i.e. pole height: $ant_height (meters)"
fi
if [ -z $out_solformat ]; then
  echo "  Output solution format: argument not, using default (llh)"
  else echo "  Output solution format: $out_solformat"
fi
if [ -z $out_solstatic ]; then
  echo "  Output solution static: argument not provided, using default (single)"
  else echo "  Output solution static: $out_solstatic"
fi

# Variables
workdir=$PWD
out_file="position-$timestamp.pos"
basedir="base"
roverdir="rover"
extobs="\.[0-2][0-9]o$|mo\.rnx$|\.obs$"
extnav="\.[0-2][0-9][gln]$|mn\.rnx$|nav$"
extzip="\.zip$|\.7z$|\.rar$|\.gzip$"
extubx="\.ubx$"
tmp_conf_file="conf-file-$timestamp.conf"
tmp_ant_file="ant-file-$timestamp.atx"
tmpdir=`mktemp -d -t ppk.XXXXX`
trap 'rm -rf -- "$tmpdir"' EXIT #Deletes tmpdir on exit

# Names of file patterns
name_for_file_type () {
  local pattern=$1
  if [ "$pattern"="$extzip" ]; then
  echo "ZIP"
  elif [ "$pattern"="$extubx" ]; then
  echo "u-blox"
  elif [ "$pattern"="$extobs" ]; then
  echo "RINEX observations"
  elif [ "$pattern"="$extnav" ]; then
  echo "RINEX navigation"
  else
  echo "unknown"
  fi
}

# Create dirs, copy files
mkdir -p $tmpdir/$basedir
cp $base_file $tmpdir/$basedir
if [ ! -z $nav_file ]; then cp $nav_file $tmpdir/$basedir; fi
mkdir -p $tmpdir/$roverdir
cp $rover_file $tmpdir/$roverdir
cp $conf_file $tmpdir/$tmp_conf_file
if [ ! -z "$ant_file" ]; then
  cp $ant_file $tmpdir/$tmp_ant_file
fi
cd $tmpdir

# Edit conf file
if [ ! -z "$ant_file" ]; then
  sed -i "s/ant1-anttype       =.*$/ant1-anttype       =$ant_type/g" $tmp_conf_file
  sed -i "s/file-rcvantfile    =.*$/file-rcvantfile    =$tmp_ant_file/g" $tmp_conf_file
fi
if [ ! -z "$ant_height" ]; then
  sed -i "s/ant1-antdelu       =.*$/ant1-antdelu       =$ant_height          # (m)/g" $tmp_conf_file
fi
if [ ! -z "$out_solformat" ]; then
  sed -i "s/out-solformat      =.*$/out-solformat      =$out_solformat        # (0:llh,1:xyz,2:enu,3:nmea)/g" $tmp_conf_file
  else
  sed -i "s/out-solformat      =.*$/out-solformat      =llh        # (0:llh,1:xyz,2:enu,3:nmea)/g" $tmp_conf_file
fi
if [ ! -z "$out_solstatic" ]; then
  sed -i "s/out-solstatic      =.*$/out-solstatic      =$out_solstatic        # (0:all,1:single)/g" $tmp_conf_file
  else
  sed -i "s/out-solstatic      =.*$/out-solstatic      =single        # (0:all,1:single)/g" $tmp_conf_file
fi

# Check whether dirs exist
if [ ! -d $basedir ]; then
  echo -e "\n  No $basedir dir found. Create it and place the base data in it" 2>&1 | tee -a $log_filename
  exit 1
fi

if [ ! -d $roverdir ]; then
  echo -e "\n  No $roverdir dir found. Create it and place the rover data in it" 2>&1 | tee -a $log_filename
  exit 1
fi

# Check whether dirs are empty
check_empty_dir () {
  local dir=$1
  local n=(`ls $dir | wc -l`)
  if [ $n -eq 0 ]; then
  echo -e "\n  No files available in $dir" 2>&1 | tee -a $log_filename
  exit 1
  fi
}
check_empty_dir $basedir
check_empty_dir $roverdir

# Path to files
path_files () {
  local dir=$1
  local pattern=$2
  local file_type=`name_for_file_type $pattern`
  local result=`ls $dir | grep -Ei "$pattern"`
  local n_result=`ls $dir | grep -Ei "$pattern" | wc -l`
  if [ $n_result -gt 0 ]; then
  echo -e "$dir/$result"
  fi
}

# Helper function for handling UBX files
handle_ubx () {
  local dir=$1
  local ubx=$2
  convbin -d $dir -ti $time_interval -ro -TADJ=1 $ubx
}

# Helper function for handling ZIP files
handle_zip () {
  local dir=$1
  local zip_file=$2
  unzip -n -j $zip_file -d $dir
}

# Helper function for selecting navigation file
nav_files () {
  local basenav=`path_files $basedir $extnav`
  local n_basenav=`path_files $basedir $extnav | wc -l`
  local rovernav=`path_files $roverdir $extnav`
  local n_rovernav=`path_files $roverdir $extnav | wc -l`
  if [ $n_basenav -gt 0 ]; then
  echo "$basenav"
  elif [ $n_rovernav -gt 0 ]; then
  echo "$rovernav"
  else
  echo -e "\n  No navigation file in base directory or rover directory" 2>&1 | tee -a $log_filename
  exit 1
  fi
}

# Helper function for checking required RINEX OBS files
check_rinex_obs () {
  local roverobs=`path_files $roverdir $extobs`
  local n_roverobs=`path_files $roverdir $extobs | wc -l`
  local baseobs=`path_files $basedir $extobs`
  local n_baseobs=`path_files $basedir $extobs | wc -l`
  local nav=`nav_files`
  local n_nav=`nav_files | wc -l`
  if [[ $n_roverobs -eq 1 && $n_baseobs -eq 1 && $n_nav -gt 0 ]]; then
  echo 1
  fi
}

# Wrapper of rnx2rtkp
my_rnx2rtkp () {
  local roverobs_def=$1
  local baseobs_def=$2
  local nav_def=$3
  rnx2rtkp -k $tmp_conf_file -ti $time_interval -o $out_file $roverobs_def $baseobs_def $nav_def 2>&1 | tee -a $log_filename
}

# PPK
ppk () {
  if [[ `check_rinex_obs` -ne 1 ]]; then
  handle_zip $roverdir `path_files $roverdir $extzip`
  handle_zip $basedir `path_files $basedir $extzip`
  handle_ubx $roverdir `path_files $roverdir $extubx`
  handle_ubx $basedir `path_files $basedir $extubx`
  fi
  my_rnx2rtkp `path_files $roverdir $extobs` `path_files $basedir $extobs` `nav_files`
}
ppk

# Copy position file to workdir only if .pos if present
pospat="$tmpdir/*.pos"
if ls $pospat 1> /dev/null 2>&1; then
  echo "  Position file generated. Copying to directory $workdir/ppk-$timestamp"
  mkdir -p $workdir/ppk-$timestamp
  for j in `ls *"$timestamp"*`; do cp $j $workdir/ppk-$timestamp; done
  else echo "  No position file generated. Exiting"
fi

exit
