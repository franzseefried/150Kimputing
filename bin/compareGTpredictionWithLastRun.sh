#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
if [ ${dbsystem} != "rapid" ]; then
   DEUTZ_DIR=/qualstororatest01/argus_${dbsystem}
fi
set -o nounset
set -o errexit

### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the old result file"
  echo "Usage: $SCRIPT -c <string>"
  echo "  where <string> specifies the new result file"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b:c: FLAG; do
  case $FLAG in
    b) # set option "b"
      export fileold=$(echo $OPTARG)
      ;;
    c) # set option "c"
      export filenew=$(echo $OPTARG)
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that files are not empty
if [ ! -s ${fileold} ]; then
      usage '${fileold} ist leer oder existiert nicht'
fi
if [ ! -s ${filenew} ]; then
      usage '${filenew} ist leer oder existiert nicht'
fi

if [ -s ${filenew} ] && [ -s ${fileold} ]; then
defectcode=$(basename ${filenew} | cut -d'.' -f2)
echo ${defectcode} Vergleich old $fileold vs new ${filenew}
(echo "TVD;GTalt;GTneu;";
awk 'BEGIN{FS=" ";OFS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));NP[$1]=$2;}} \
    else {sub("\015$","",$(NF));ECD=NP[$1]; \
    if      (ECD != "" && $2 != ECD) {print $1,ECD,$2}}}' ${fileold} ${filenew} ) > $RES_DIR/${defectcode}_aenderung_${oldrun}_${run}.csv
n=$(wc -l $RES_DIR/${defectcode}_aenderung_${oldrun}_${run}.csv | awk '{print $1-1}')
echo "habe ${n} Tiere mit gewechseltem ${defectcode} Status im Vgl. zum letzen Mal:"
if [ ${n} -gt 0 ]; then
echo "check file $RES_DIR/${defectcode}_aenderung_${oldrun}_${run}.csv"
#cat $RES_DIR/${defectcode}_aenderung_${oldrun}_${run}.csv
fi

#if [ ${breed} == HOL ]; then
#    echo "ftp upload for SHZV"
#    $BIN_DIR/ftpUploadOf1File.sh -f ${defectcode}_aenderung_${oldrun}_${run}.csv -o ${RES_DIR} -z Einzelgen
#fi
fi



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
