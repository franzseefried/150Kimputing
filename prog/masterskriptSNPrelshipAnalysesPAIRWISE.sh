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
#Prinzip: Gmatrix NICHT mehr komplett als txt file schreiben sondern direkt die pairwise relationships schreiben mit snp1101.

#remove files if they exist due to re-running
rm -f ${RES_DIR}/${1}.out.AnimalMV.snp1101.${run}.txt 
rm -f ${RES_DIR}/${1}.out.AnimalVV.snp1101.${run}.txt

##################################
echo "Run SNP1101 GRM now for $1"
$BIN_DIR/usePLINKandRunSNP1101GRMpairwise.sh ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/usePLINKandRunSNP1101GRMpairwise.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "wait till MV & VVcheck-result files exist for $1"
$BIN_DIR/waitTillVVMVcheckIsReadyToContinue.sh ${1} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/waitTillVVMVcheckIsReadyToContinue.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Suche suspekte MVs for $1"
$BIN_DIR/validateGenRelMatAndPickoutSuspiciousPairsMV.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/validateGenRelMatAndPickoutSuspiciousPairsMV.sh $1
        exit 1
fi
##################################
echo "Suche suspekte VVs for $1"
$BIN_DIR/validateGenRelMatAndPickoutSuspiciousPairsVV.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 5"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/validateGenRelMatAndPickoutSuspiciousPairsVV.sh.sh $1
        exit 1
fi
##################################
echo "Run SNP1101 entire GRM matrix now for ply-Skript $1"
nohup $BIN_DIR/usePLINKandRunSNP1101GRM.sh ${1} 2>&1 > $LOG_DIR/3c-${1}.entireRelMatrix.log &
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 6"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/usePLINKandRunSNP1101GRM.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "send finishing mail"
$BIN_DIR/sendFinishingMail.sh ${PROG_DIR}/${SCRIPT} $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 9"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh $1
        exit 1
fi
echo "----------------------------------------------------"
echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
