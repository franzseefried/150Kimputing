#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " " 

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################

#es wurde vorher ein Dummy Vater Dummy Mutter für Tiere mit unbekanntem Elter gesetzt, damit Fimpute einen möglichen Elter sucht, wenn keiner gefunden: Tiere raus aus dem Genotypenfile

ps fax | grep -i FImpute_Linux | tr -s ' ' |awk -v gg=${MAIN_DIR} '{if($9 ~ gg || $5 ~ gg || $6 ~ gg) print $1}' | while read job; do kill ${job} > /dev/null 2>&1 ; done


if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
else
set -o errexit
set -o nounset

breed=${1}

	sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/ped_umcodierung.txt.${breed}.srt

	TUMMY1=$(cat $WORK_DIR/DUMMYsire.${breed} | cut -d' ' -f1)

	#loesche Tiere mit unbekanntem Elte aus Genotypenfile, hole nur die die vorher dummyelter bekommen haben
	grep "No match" ${FIM_DIR}/${breed}_PEDICHECKout/parentage_test.txt |\
            awk -v T1=${TUMMY1} '{if($2 == T1) print $1" N"}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.TiereMitUnbekanntemVater.srt
	i=Sire
	#liste fuer Verbaende:
	grep "No match" ${FIM_DIR}/${breed}_PEDICHECKout/parentage_test.txt |\
           awk -v s=${i} '{if($4 == s) print}' |\
           awk -v T1=${TUMMY1} '{if($2 == T1 ) print $1,"Vater"}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.TiereMitUnbekanntemSire.srt
	
fi


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

