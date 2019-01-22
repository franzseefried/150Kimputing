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
	
        TUMMY2=$(cat $WORK_DIR/DUMMYdam.${breed} | cut -d' ' -f2)
        TUMMY1=$(cat $WORK_DIR/DUMMYsire.${breed} | cut -d' ' -f1)

	mv $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno  $FIM_DIR/${breed}BTAwholeGenome_FImpute.genoORG

    (cat $TMP_DIR/${breed}.TiereMitUnbekanntemVater.srt ; $TMP_DIR/${breed}.TiereMitUnbekannterMutter.srt)|sort -T ${SRT_DIR} -u > $TMP_DIR/${breed}.TiereMitUnbekanntemELTER.srt
	(head -1 $FIM_DIR/${breed}BTAwholeGenome_FImpute.genoORG ;
        awk 'BEGIN{FS=" ";OFS=" "}{ \
            if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));NDel[$1]=$2;}} \
            else {sub("\015$","",$(NF));DLT="0";DLT=NDel[$1]; \
            if   (DLT == "") {print $0}}}' $TMP_DIR/${breed}.TiereMitUnbekanntemELTER.srt $FIM_DIR/${breed}BTAwholeGenome_FImpute.genoORG | grep -v "ID Chip") > $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno


	#mache Liste fuer Verbaende, hier mit unterscheidung ob Vater oder Mutter, neu 14.05.2014
	grep "No match" ${FIM_DIR}/${breed}_PEDICHECKout/parentage_test.txt |\
           awk '{if($4 == "Sire") print}' |\
           awk -v T1=${TUMMY1} -v T2=${TUMMY2} '{if($2 == T1 || $2 == T2 ) print $1,$4}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 >> $TMP_DIR/${breed}.TiereMitUnbekanntemSire.srt
	sort -T ${SRT_DIR} -u -t' ' -k1,1 $TMP_DIR/${breed}.TiereMitUnbekanntemSire.srt -o $TMP_DIR/${breed}.TiereMitUnbekanntemSire.srt
	
	grep "No match" ${FIM_DIR}/${breed}_PEDICHECKout/parentage_test.txt |\
           awk '{if($4 == "Dam") print}' |\
           awk -v T2=${TUMMY2} -v T2=${TUMMY2} '{if($3 == T2 || $3 == T1 ) print $1,$4}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 >> $TMP_DIR/${breed}.TiereMitUnbekannterDam.srt
	sort -T ${SRT_DIR} -u -t' ' -k1,1 $TMP_DIR/${breed}.TiereMitUnbekannterDam.srt -o $TMP_DIR/${breed}.TiereMitUnbekannterDam.srt
	
	echo " ";
	echo " ";
	(cat $TMP_DIR/${breed}.TiereMitUnbekanntemSire.srt;
	    cat $TMP_DIR/${breed}.TiereMitUnbekannterDam.srt;)| sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.TiereMitUnbekanntemX.srt
	(echo "TierTVD;TierID;Problem"
	    join -t' ' -o'2.5 1.1 1.2' -1 1 -2 1  $TMP_DIR/${breed}.TiereMitUnbekanntemX.srt $TMP_DIR/ped_umcodierung.txt.${breed}.srt | tr ' ' ';' | sort -T ${SRT_DIR} -t';' -k1,1 -k2,2r)  > $ZOMLD_DIR/${breed}.TiereMitUnbekanntemElter_KEINEimputation.csv
	n=$(wc -l $ZOMLD_DIR/${breed}.TiereMitUnbekanntemElter_KEINEimputation.csv | awk '{print $1-1}')
	echo " "
	echo Loesche ${n} Tiere da sie mindestens einen Elter 0 haben
	echo " ";
rm -f $TMP_DIR/ped_umcodierung.txt.${breed}.srt
	
fi


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
