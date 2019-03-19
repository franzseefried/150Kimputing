#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
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
set -o errexit
set -o nounset

START_DIR=pwd


if [ ${breed} == "BSW" ]; then
	zofol=$(echo "bvch")
fi
if [ ${breed} == "HOL" ]; then
	zofol=$(echo "shb")
fi
if [ ${breed} == "VMS" ]; then
    zofol=$(echo "vms")
fi

if [ ${snpstrat} == "F" ]; then
if ! test -s $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt; then
   echo "you have choosen a fixSNPdatum, where I tried to take the SNPmap now"
   echo "that map $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt does not exist or has size ZERO"
   echo "change parameter or check"
   $BIN_DIR/sendErrorMail.sh ${SCRIPT} $1
   exit 1
fi
else
   echo "you have NOT choosen a fixSNPdatum, which meacn you want to select a new SNPset"
   echo "for that you have to creat an OVERall snp map and eliminate all problems with coodinates etc..."
   echo "change parameter or do this first"
   $BIN_DIR/sendErrorMail.sh ${SCRIPT} $1
   exit 1
fi



#define breed loop
colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ${SNPlevel} | awk '{print $1}')
colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')
colIGX=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep IntergenomicsCode | awk '{print $1}')
CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v ee=${dichte} 'BEGIN{FS=";"}{if( $cc == ee ) print $dd }' ${REFTAB_CHIPS})
lgtC=$(echo ${CHIPS} | wc -w | awk '{print $1}')
if [ ${lgtC} -eq 0 ]; then
  echo "keie Chips angegeben in ${REFTAB_CHIPS} in Kolonne  ${IMPUTATIONFLAG} "
  exit 1
fi


#generelle Strategie: Nimm Intergenomics maps so wie sie sind bzgl pos. 
#bei den SNPs die in der Zielmap sind, mache ein update auf der position und dem BTA, die anderen lass so

for chip in ${CHIPS}; do
   chipINTid=$(awk -v ccc=${chip} -v ii=${colIGX} 'BEGIN{FS=";"}{if($5 == ccc) print $ii}' ${REFTAB_CHIPS} )
   echo $chip $chipINTid
   sed 's/Dominant Red/Dominant_Red/g' $MAP_DIR/intergenomics/SNPindex_${chipINTid}_new_order.txt |\
      awk '{print $1,$2,$3,$4}' | sort -T ${SRT_DIR} -t' ' -k1,1 |\
      join -t' ' -o'1.1 1.2 1.3 1.4 2.2 2.3' -a1 -e'-' -1 1 -2 1 - <(awk '{print $1,$2,$3,$4,$5}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt | sort -T ${SRT_DIR} -t' ' -k1,1) |\
      awk '{if($5 == 0 || $5 == "-") print $2,$3,$1,"0",$4; else print $2,$5,$1,"0",$6}' | sort -T ${SRT_DIR} -t' ' -k1,1n | awk '{print $2,$3,$4,$5}' | awk '{if($1 > 30) print "30",$2,$3,$4; else print $1,$2,$3,$4}'  > $WORK_DIR/${breed}.${chip}.map
   nE=$(wc -l  $WORK_DIR/${breed}.${chip}.map | awk '{print $1}')
   nS=$(wc -l  $MAP_DIR/intergenomics/SNPindex_${chipINTid}_new_order.txt | awk '{print $1}')
   if [ ${nE} != ${nS} ]; then echo "OOOPS $chip $chipINTid"; fi
done



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
