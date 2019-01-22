#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit
set -o nounset

START_DIR=pwd

if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
elif [ ${1} == "BSW" ] || [ ${1} == "HOL" ]  || [ ${1} == "VMS" ]; then

if [ ${1} == "BSW" ]; then
	zofol=$(echo "bvch")
fi
if [ ${1} == "HOL" ]; then
	zofol=$(echo "shb")
fi
if [ ${1} == "VMS" ]; then
        zofol=$(echo "vms")
fi
else 
  echo "unbekannter Systemcode BSW VMS oder HOL erlaubt"
  exit 1
fi


if [ -z $2 ]; then
   echo "brauche den Code für die Chipdichte HD oder LD"
   exit 1
elif [ $2 == "LD" ] || [ $2 == "HD" ]; then
   echo $2 > /dev/null
   dichte=${2}
else
   echo "Der Code fuer die Chipdichte muss LD oder HD sein, ist aber ${2}"
   exit 1
fi

set -o nounset

set -o nounset
breed=${1}

if [ ${snpstrat} == "F" ]; then
if ! test -s $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt; then
   echo "you have choosen a fixSNPdatum, where I tried to take the SNPmap now"
   echo "that map $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt does not exist or has size ZERO"
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
colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ImputationDensityLD150K | awk '{print $1}')
colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')
colIGX=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep IntergenomicsCode | awk '{print $1}')
CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v ee=${dichte} 'BEGIN{FS=";"}{if( $cc == ee ) print $dd }' ${REFTAB_CHIPS})
lgtC=$(echo ${CHIPS} | wc -w | awk '{print $1}')
if [ ${lgtC} -eq 0 ]; then
  echo "keie Chips angegeben in ${REFTAB_CHIPS} in Kolonne ImputationDensityLD150K "
  exit 1
fi


#generelle Strategie: Nimm Intergenomics maps so wie sie sind bzgl pos. 
#bei den SNPs die in der Zielmap sind, mache ein update auf der position und dem BTA, die anderen lass so

for chip in ${CHIPS}; do

   chipINTid=$(awk -v ccc=${chip} -v ii=${colIGX} 'BEGIN{FS=";"}{if($5 == ccc) print $ii}' ${REFTAB_CHIPS} )
   echo $chip $chipINTid
   sed 's/Dominant Red/Dominant_Red/g' $MAP_DIR/intergenomics/SNPindex_${chipINTid}_new_order.txt |\
      awk '{print $1,$2,$3,$4}' | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 |\
      join -t' ' -o'1.1 1.2 1.3 1.4 2.2 2.3' -a1 -e'-' -1 1 -2 1 - <(awk '{print $1,$2,$3,$4,$5}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1) |\
      awk '{if($5 == 0 || $5 == "-") print $2,$3,$1,"0",$4; else print $2,$5,$1,"0",$6}' | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1n | awk '{print $2,$3,$4,$5}' | awk '{if($1 > 30) print "30",$2,$3,$4; else print $1,$2,$3,$4}'  > $WORK_DIR/${breed}.${chip}.map
   nE=$(wc -l  $WORK_DIR/${breed}.${chip}.map | awk '{print $1}')
   nS=$(wc -l  $MAP_DIR/intergenomics/SNPindex_${chipINTid}_new_order.txt | awk '{print $1}')
   if [ ${nE} != ${nS} ]; then echo "OOOPS $chip $chipINTid"; fi
done



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
