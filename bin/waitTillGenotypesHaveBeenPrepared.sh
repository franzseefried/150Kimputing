#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options bsw, hol or vms"
  echo "Usage: $SCRIPT -c <string>"
  echo "  where <string> specifies the Density: e.g. LD / HD"
  echo "Usage: $SCRIPT -d <string>"
  echo "  where <string> specifies the Imputation level: e.g. LD150KImputation"
  exit 1
}
### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi
while getopts :b:c:d: FLAG; do
  case $FLAG in
    b) # set option "b"
      export breed=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${breed} == "BSW" ] || [ ${breed} == "HOL" ] || [ ${breed} == "VMS" ]; then
          echo ${breed} > /dev/null
      else
          usage "Breed not correct, must be specified: bsw / hol / vms using option -b <string>"
          exit 1
      fi
      ;;
    c) # set option "c"
      export dichte=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${dichte} == "HD" ] || [ ${dichte} == "LD" ]; then
          echo ${dichte} > /dev/null
      else
          usage "Dichte not correct, must be specified: bsw / hol / vms using option -b <string>"
          exit 1
      fi
      ;;
    d) # set option "d"
      export SNPlevel=$(echo $OPTARG)
      ;;
     *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that breed is not empty
if [ -z "${breed}" ]; then
      usage 'breed not specified, must be specified using option -b <string>'   
fi
if [ -z "${dichte}" ]; then
      usage 'Dichte not specified, must be specified using option -c <string>'   
fi
if [ -z "${SNPlevel}" ]; then
      usage 'code for SNPlevel not specified, must be specified using option -d <string>'   
fi
START_DIR=$(pwd)
set -o errexit
set -o nounset
if [ ${breed} == "BSW" ]; then
	zofol=$(echo "bvch")
fi
if [ ${breed} == "HOL" ]; then
	zofol=$(echo "shb")
fi
if [ ${breed} == "VMS" ]; then
    zofol=$(echo "vms")
fi


#define breed loop
colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ${SNPlevel} | awk '{print $1}')
colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')
#DENSITIES=$(awk -v cc=${colDENSITY} 'BEGIN{FS=";"}{ if(NR > 1) print $cc }' ${REFTAB_CHIPS} | sort -T ${SRT_DIR} -u | awk '{if($1 != "") print}')
DENSITIES=${dichte}

echo ${DENSITIES}

#teil Plink
Plinkcheck () {

for dens in ${DENSITIES} ; do
existshot=N
existresult=Y
while [ ${existshot} != ${existresult} ]; do
if test -s $TMP_DIR/${breed}${dens}.bed; then
existshot=Y
fi
done
done

echo "Plink binary files exist, check if they are ready"
for dens in ${DENSITIES} ; do
shotcheck=same
shotresult=unknown
current=$(date +%s)
while [ ${shotcheck} != ${shotresult} ]; do
 lmod=$(stat -c %Y $TMP_DIR/${breed}${dens}.bed)
 #echo $current $lmod
 if [ ${lmod} > 360 ]; then
    shotresult=same
    #shotresult=$(${BIN_DIR}/check2snapshotsOF1file.sh $TMP_DIR/${breed}${dens}.bed | awk '{print $3}')
    echo "$TMP_DIR/${breed}${dens}.bed is ready"
 fi
done
done
}

Plinkcheck



#check plink logfiles
$BIN_DIR/smallcheckPLINKlogfiles.sh ${breed}



echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

