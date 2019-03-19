#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL oder VMS "
    exit 1
elif [ ${1} == "BSW" ]; then
        echo $1 > /dev/null
elif [ ${1} == "HOL" ]; then
        echo $1 > /dev/null
elif [ ${1} == "VMS" ]; then
        echo $1 > /dev/null
else
        echo " $1 != BSW / HOL / VMS, ich stoppe"
        exit 1
fi

breed=$1


#######Funktionsdefinition
getColmnNrSemicl () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(head -1 $2 | tr ';' '\n' | grep -n "^$1$" | awk -F":" '{print $1}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}


#get Info about SNP from Reftab
getColmnNrSemicl ExtractGenotypesFromChipData ${REFTAB_SiTeAr} ; colEXG=$colNr_
getColmnNrSemicl CodeResultfile ${REFTAB_SiTeAr} ; colCSGI=$colNr_
getColmnNrSemicl BTA ${REFTAB_SiTeAr} ; colGSB=$colNr_
getColmnNrSemicl PredictionAlgorhithm ${REFTAB_SiTeAr} ; colABAASGI=$colNr_
getColmnNrSemicl IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBRD=$colNr_


declare -a algis=$(awk -v a=${colABAASGI} -v b=${colCSGI} -v c=${colIMPBRD} -v d=${breed} 'BEGIN{FS=";"}{if($c ~ d) print $a}' ${REFTAB_SiTeAr} | sort -u | grep \[A-Z\] |tr '\n' ' ')
if [ ${#algis[@]} -eq 0 ]; then
echo "PredictionAlgortithm array is empty:  ${#algis[@]}"
exit 1
fi


echo " "
echo " "
for iA in ${algis[@]}; do
if [ ${iA} == "SVM" ]; then kuerzel=SVMbasedGenotypePrediction;fi
if [ ${iA} == "SINGLEGENE" ]; then kuerzel=SingleGeneImputation;fi
if [ ${iA} == "GENOMEWIDE" ]; then kuerzel=PullVariantFromGenomewideSystem;fi
if [ ${iA} == "HAPLOTYPE" ]; then kuerzel=SingleLocusHaplotyping;fi

echo "${iA}"
grep "Tiere mit gewechseltem" $LOG_DIR/${kuerzel}*${breed}.*
echo " "
echo " "
done


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
