#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
export lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit

### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -f <string>"
  echo "  where <string> specifies the file to be uploaded"
  #echo "  where <string> valid options are BSW or HOL"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed where breed -b is"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
  exit 1
fi

while getopts "f:b:" FLAG; do
  case $FLAG in
    f) # set option "f"
      upf=$(echo $OPTARG )
      if [ ! -z ${upf} ] ; then
          echo ${upf} > /dev/null
      else
          usage 'Parameter for file to be tranferred is NULL, must be specified using -f <string> option '
          exit 1
      fi
      ;;
    b) # set option "b"
      breed=$(echo $OPTARG )
      if [ ! -z ${breed} ] ; then
          echo ${breed} > /dev/null
      else
          usage 'Parameter for breed is NULL, must be specified using -b <string> option '
          exit 1
      fi
      ;;   
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
if test -s ${upf} ; then
   echo "file being checked:"
   ls -trl ${upf}
   echo " "
   nAusgang=$(wc -l ${upf} | awk '{print $1}' )
   
   nNULL=$(awk 'BEGIN{FS=";";OFS=";"}{ if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$15;}} else {sub("\015$","",$(NF));STAT="0";sD=CD[$1]; if   (sD != "") {print $0}}}' ${upf} ${ZOMLD_DIR}/${breed}_SammelLOG-${run}.csv |awk 'BEGIN{FS=";"}{if($11 == "NULL" || $12 == "NULL" || $13 == "NULL") print}'|wc -l|awk '{print $1}')
   nNOTOK=$(awk 'BEGIN{FS=";";OFS=";"}{ if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$15;}} else {sub("\015$","",$(NF));STAT="0";sD=CD[$1]; if   (sD != "") {print $0}}}' ${upf} ${ZOMLD_DIR}/${breed}_SammelLOG-${run}.csv |awk 'BEGIN{FS=";"}{if($11 == "NOT-OK" || $12 == "NOT-OK" || $13 == "NOT-OK") print}'|wc -l|awk '{print $1}')
   
   pNULL=$(echo ${nNULL} ${nAusgang}   | awk '{printf "%3.3f\n", ($1/$2)*100}')
   pNOTOK=$(echo ${nNOTOK} ${nAusgang} | awk '{printf "%3.3f\n", ($1/$2)*100}')
   #echo ${nAusgang} ${nNULL} ${nNOTOK} ${pNULL} ${pNOTOK} ${upf}
   echo ${upf} ${pNULL}  | awk -v f=${upf} -v p=${pNULL} -v q=${nNULL} '{printf "%-10s%-40s%-50s%3.3f%-30s%+5s\n", "&&&&&&&&& ",f," Proportion (%) of Samples with NULL   result:",p," ^= absolute no. of samples:",q}' 
   echo ${upf} ${pNOTOK} | awk -v f=${upf} -v p=${pNOTOK} -v q=${nNOTOK} '{printf "%-10s%-40s%-50s%3.3f%-30s%+5s\n", "&&&&&&&&& ",f," Proportion (%) of Samples with NOT-OK result:",p," ^= absolute no. of samples:",q}' 
else
   echo " "
   echo "file to be checked ${upf} does not exist of has size zero"
   echo " "
fi

echo " "
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}
