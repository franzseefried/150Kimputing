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



rm -f $RES_DIR/${1}.GenomicFcoefficient.${run}.txt $RES_DIR/${1}.PedigreeFcoefficient.${run}.txt
##################################
echo "Wait till SNP1101 prep from SNPrelship analyses is ready for $1"
for ffile in $LOG_DIR/${1}.GRM.SMP1101.log; do 
$BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh ${1} ${ffile} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh $1
        exit 1
fi
echo "----------------------------------------------------"
done
##################################
echo "get Genomic and Pedigree F for $1"
$BIN_DIR/usePLINKandRunSNP1101INBREEDINGpairwise.sh ${1} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/usePLINKandRunSNP1101INBREEDINGpairwise.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Wait till Relationshipfiles are ready for $1"
for ffile in $RES_DIR/${1}.GenomicFcoefficient.${run}.txt $RES_DIR/${1}.PedigreeFcoefficient.${run}.txt; do
$BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh ${1} ${ffile} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/bin/waitTillFileInARG2HasBeenPrepared.sh $1
        exit 1
fi
echo "----------------------------------------------------"
done
##################################
echo "send finishing mail"
$BIN_DIR/sendFinishingMail.sh ${PROG_DIR}/${SCRIPT} $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh $1
        exit 1
fi
echo "----------------------------------------------------"
echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
