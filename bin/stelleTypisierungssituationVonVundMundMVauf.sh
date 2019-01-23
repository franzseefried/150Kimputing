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
    echo "brauche den Code fuer die Rasse: BSW oder HOL oder VMS "
    exit 1
else 
set -o nounset
    breed=${1}
    echo "Mache Uebericht fuer Rasse ${breed}"
    sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/pducd.srt.${breed}

    awk '{if($2 == 2) print $1,"LD"; else print $1,"HD"}' $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.allTypis.srt


    join -t' ' -o'2.5 1.2 2.2 2.3' -1 1 -2 1 $TMP_DIR/${breed}.allTypis.srt $TMP_DIR/pducd.srt.${breed} |\
           sort -T ${SRT_DIR} -t' ' -k3,3 |\
           join -t' ' -o'1.1 1.2 1.3 2.2 1.4' -e'-' -a1 -1 3 -2 1 - $TMP_DIR/${breed}.allTypis.srt |\
           sort -T ${SRT_DIR} -t' ' -k5,5 |\
           join -t' ' -o'1.1 1.2 1.3 1.4 1.5 2.2' -e'-' -a1 -1 5 -2 1 - $TMP_DIR/${breed}.allTypis.srt |\
           sort -T ${SRT_DIR} -t' ' -k5,5 |\
           join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 2.2' -e'-' -a1 -1 5 -2 1 - $TMP_DIR/pducd.srt.${breed} |\
           sort -T ${SRT_DIR} -t' ' -k7,7 |\
           join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 1.7 2.2' -e'-' -a1 -1 7 -2 1 -  $TMP_DIR/${breed}.allTypis.srt |\
           sort -T ${SRT_DIR} -t' ' -k3,3 |\
           join -t' ' -o'1.1 1.2 2.5 1.4 1.5 1.6 1.7 1.8' -e'-' -a1 -1 3 -2 1 -  $TMP_DIR/pducd.srt.${breed} |\
           sort -T ${SRT_DIR} -t' ' -k5,5 |\
           join -t' ' -o'1.1 1.2 1.3 1.4 2.5 1.6 1.7 1.8' -e'-' -a1 -1 5 -2 1 -  $TMP_DIR/pducd.srt.${breed} |\
           sort -T ${SRT_DIR} -t' ' -k7,7 |\
           join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 2.5 1.8' -e'-' -a1 -1 7 -2 1 -  $TMP_DIR/pducd.srt.${breed} |\
           sort -T ${SRT_DIR} -t' ' -k1,1 > $RES_DIR/${breed}TypiSituationVMMV_${run}.txt

    (echo "n ChipTier ChipV ChipM ChipMV"
	cut -d' ' -f2,4,6,8 $RES_DIR/${breed}TypiSituationVMMV_${run}.txt | sort -T ${SRT_DIR} | uniq -c | awk '{print $1,$2,$3,$4,$5}' | sort -T ${SRT_DIR} -t' ' -k1,1nr )| awk '{printf "%+10s%+10s%+10s%+10s%+10s\n", $1,$2,$3,$4,$5}' 
    (echo "n ChipTier ChipV ChipM ChipMV"
	cut -d' ' -f2,4,6,8 $RES_DIR/${breed}TypiSituationVMMV_${run}.txt | sort -T ${SRT_DIR} | uniq -c | awk '{print $1,$2,$3,$4,$5}' | sort -T ${SRT_DIR} -t' ' -k1,1nr )| tr ' ' ';' > $RES_DIR/${breed}_ChipStatus.summarylist${run}.csv
    n=$(awk '{if($2 == "LD" && $4 == "-") print}' $RES_DIR/${breed}TypiSituationVMMV_${run}.txt | wc -l | awk '{print $1}')
    echo " "
    if [ ${n} -gt 0 ]; then
	awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f2,3,4,5,9,11,12 | sed 's/ //g' | tr ';' ' ' | awk '{print $1,substr($2,4,16),$3,$4,$5,$6,$7}' | sort -T ${SRT_DIR} -t' ' -k1,1  > $TMP_DIR/g.srt
	(echo "VaterName Tier ChipTier Vater ChipVater Mutter ChipMutter MV ChipMV NameTier GebdatTier NameVater RassecodeTier Blutanteil";
	    awk '{if($2 == "LD" && $4 == "-") print}' $RES_DIR/${breed}TypiSituationVMMV_${run}.txt |\
               sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 2.3 2.4 2.5 2.6 2.7 2.1' -1 1 -2 1 - $TMP_DIR/g.srt |\
               sort -T ${SRT_DIR} -t' ' -k12,12n -k10,10 |\
               awk '{print $11" "$14" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "$10" "$11" "$12" "$13}') | tr ' ' ';'  > $ZOMLD_DIR/${breed}LDTiereOHNEtypisiertenVater_${run}.csv
	    echo " ";
            echo "...es hat LD Tiere deren Vater nicht Typisiert ist, siehe $ZOMLD_DIR/${breed}LDTiereOHNEtypisiertenVater_${run}.txt"
	    echo "Rueckmledung im gesammelten Logfile"
            echo " "
    else
        echo " "
	echo "Supi, alle LD Tiere haben einen typisierten Vater"
        echo " "
    fi
rm -f $TMP_DIR/pducd.srt.${breed}
rm -f $TMP_DIR/${breed}.allTypis.srt
rm -f $TMP_DIR/g.srt
fi





echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

