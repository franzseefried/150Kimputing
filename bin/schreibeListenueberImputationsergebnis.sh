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
elif [ $1 == 'BSW' ] || [ $1 == 'HOL' ]  || [ $1 == 'VMS' ] ; then
set -o nounset
    breed=$(echo "$1")

    cut -d' ' -f1,5 $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/${breed}id1id2.reftab

    cp $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt  $HIS_DIR/${breed}.RUN${run}snp_info.txt
	#aktuelles Ergebnis Tierliste
    awk '{print $1,$2}' $FIM_DIR/${breed}BTAwholeGenome.out/genotypes_imp.txt > $TMP_DIR/${breed}.Tierresult
    (echo "TVD Chip";
	$BIN_DIR/awk_umkodierungID1zuID2 $TMP_DIR/${breed}id1id2.reftab  $TMP_DIR/${breed}.Tierresult ) >  $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis
    #sort -T ${SRT_DIR} -t' ' -k1,1 $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis > $TMP_DIR/${breed}.imres.${oldrun}
    echo "Uebersicht Ergebnis Imputation $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis"
    echo " "
    echo "n ChipTyp"
    cut -d' ' -f2 $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis | grep -v -i chip | sort -T ${SRT_DIR}  | uniq -c | awk '{print $1,$2}' | sort -T ${SRT_DIR} -t' ' -k2,2n
    echo " "
    rm -f $TMP_DIR/${breed}.Tierresult
    rm -f $TMP_DIR/${breed}id1id2.reftab
else
    echo "komischer breedcode :-("
    exit 1
fi

echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
