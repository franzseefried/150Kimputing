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

#lokale Variable do not change!!!
chip=LD
if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
fi
if [ -z $2 ]; then
	echo "brauche den Code fuer das CHromosom, z.B. 6"
	exit 1
fi
set -o nounset
breed=${1}
BTA=${2}
echo ${BTA}
##################################################

if ! test -s ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo; then
	echo "${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo existiert nicht. Das wird hier benoetigt, daher Programmabbruch"
	exit 1
fi

noHD=$(awk -v chr=${BTA} '{if($2 == chr) print}' ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo | head -1 | awk '{print $4-1}')
noLD=$(awk -v chr=${BTA} '{if($2 == chr && $5 != 0) print}' ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo | head -1 | awk '{print $5-1}')

(head -1 ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo;
   awk -v chr=${BTA} '{if(NR > 1 && $2 == chr) print }' ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo |\
   awk -v HD=${noHD} -v LD=${noLD} '{if($5 != 0) print $1,$2,$3,$4-HD,$5-LD; else print $1,$2,$3,$4-HD,$5}' ) > $FIM_DIR/${breed}BTA${BTA}_FImpute.snpinfo
wc -l $FIM_DIR/${breed}BTA${BTA}_FImpute.snpinfo

#was fuer die haplotypecalling scripts:
cat $WORK_DIR/ped_umcodierung.txt.${breed} | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/srt.ped.${breed}


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

