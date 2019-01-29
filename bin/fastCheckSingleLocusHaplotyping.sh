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

echo " "
echo " "
echo "Single Locus Haplotyping"
grep "Tiere mit gewechseltem" $LOG_DIR/masterskriptSingleLocusHaplotyping.sh.${breed}.*
echo " "
echo " "
echo "Single Gene Imputation"
grep "Tiere mit gewechseltem" $LOG_DIR/masterskriptSingleGeneImputation*.${breed}.*
echo " "
echo " "


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
