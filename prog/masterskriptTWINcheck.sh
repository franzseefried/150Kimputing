#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit

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


#frueher via SNP-verwandtschaften, heute identical funktion in SNP1101
##################################
for i in ${1}.SNP1101FImpute.ped ${1}.SNP1101FImpute.geno ${1}.SNP1101FImpute.snplst; do
$BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh ${1} ${SMS_DIR}/${i}
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh $1
        exit 1
fi
echo "----------------------------------------------------"
done
##################################
echo "Run SNP1101 TWIN now for $1"
$BIN_DIR/runSNP1101TWINsearch.sh ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/runSNP1101TWINsearch.sh $1
        exit 1
fi
echo "----------------------------------------------------"
#################################
echo "Send finishing Mail SNP1101 TWIN now for $1"
$BIN_DIR/sendFinishingMail.sh ${PROG_DIR}/${SCRIPT} ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 3"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh $1
        exit 1
fi
echo "----------------------------------------------------"
#################################


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
