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
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS' "
    exit 1
fi
b=${1}
#check Server
ort=$(uname -a | awk '{print $1}' )
if  [ ${ort} == "Darwin" ]; then
   echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
   $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/masterskriptHandleNewSNPdata.sh
elif [ ${ort} == "Linux" ]; then
#################################
echo Step 0
for file in $RES_DIR/${b}.GenomicFcoefficient.${run}.txt $RES_DIR/${b}.PedigreeFcoefficient.${run}.txt $RES_DIR/${b}.SNPtwins.${run}.txt $ZOMLD_DIR/${b}_suspiciousVVs.${run}.csv $ZOMLD_DIR/${b}_suspiciousMVs.${run}.csv $HIS_DIR/${b}.RUN${run}.IMPresult.tierlis; do
$BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh ${b} ${file} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh
        exit 1
fi 
done
echo "----------------------------------------------------"
##################################
if false; then
echo Step 2
$BIN_DIR/waitTillHaplotypeCallsExist.sh ${b} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/waitTillHaplotypeCallsExist.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 4
$BIN_DIR/summarizeHaplotypeCarrierAcrossAllReagions.sh ${b} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/summarizeHaplotypeCarrierAcrossAllReagions.sh
        exit 1
fi
echo "----------------------------------------------------"
fi
##################################
if [ ${HDfollows} == "Y" ]; then
echo "Baue Startfile fuer HDimputing auf $1"
$BIN_DIR/quickVerarbeiteGENOMEwide-imputierte-TiereAlsStartfuerHDimputing.sh ${b} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 3"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/quickVerarbeiteGENOMEwide-imputierte-TiereAlsStartfuerHDimputing.sh $1
        exit 1
fi
else
echo "Prep for HDimputation does NOT follow since Parameter HDfollows was set to ${HDfollows}"
fi
echo "----------------------------------------------------"
##################################
echo Step 5
$BIN_DIR/sendFinishingMailWOarg2.sh ${SCRIPT} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 5"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/sendFinishingMail.sh
        exit 1
fi
echo "----------------------------------------------------"
else
   echo "oops komisches Betriebssystem ich stoppe"
   $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/masterskriptWriteLogfiles.sh
   exit 1
fi
echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
