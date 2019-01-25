#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " " 

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit

if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS' "
    exit 1
fi
if [ -z $2 ]; then
	echo "brauche den Code fuer das CHromosom, z.B. 6"
	exit 1
fi
set -o nounset
breed=${1}
BTA=${2}


startHD=$(awk -v chr=${BTA} '{if($2 == chr) print}' ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo | awk '{if(NR == 1) print $4}')
stoppHD=$(awk -v chr=${BTA} '{if($2 == chr) print}' ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo | tail -1 | awk '{print $4}')
startLD=$(awk -v chr=${BTA} '{if($2 == chr && $5 != 0) print}' ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo | awk '{if(NR == 1) print $5}')
stoppLD=$(awk -v chr=${BTA} '{if($2 == chr && $5 != 0) print}' ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo | tail -1 | awk '{print $5}')

lengthHD=$(echo ${startHD} ${stoppHD} | awk '{print ($2 - $1) + 1}')
lengthLD=$(echo ${startLD} ${stoppLD} | awk '{print ($2 - $1) + 1}')

#echo $startHD $stoppHD $startLD $stoppLD $lengthHD $lengthLD


(head -1 ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.geno;
 awk -v beg=${startHD} -v len=${lengthHD} '{if($2 == 1)print $1,$2,substr($3,beg,len)}' ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.geno;
 awk -v beg=${startLD} -v len=${lengthLD} '{if($2 == 2)print $1,$2,substr($3,beg,len)}' ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.geno;) > $FIM_DIR/${breed}BTA${BTA}_FImpute.geno





echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
