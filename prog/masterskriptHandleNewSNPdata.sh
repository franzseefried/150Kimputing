#!/bin/bash
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo Start ${SCRIPT}
date

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


#check Server
ort=$(uname -a | awk '{print $1}' )
if  [ ${ort} == "Darwin" ]; then
   echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
   $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/masterskriptHandleNewSNPdata.sh
elif [ ${ort} == "Linux" ]; then
##################################
echo Step 1
$BIN_DIR/eingangscheckGeneSeek.sh 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/eingangscheckGeneSeek.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 1b
$BIN_DIR/checkBADGeneSeekSamplesAndMakeOverview.sh 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1b"
        $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/checkBADGeneSeekSamplesAndMakeOverview.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 1c
$BIN_DIR/labcheck.summary.sh 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1c"
        $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/labcheck.summary.sh
        exit 1
fi
echo "----------------------------------------------------" 
##################################
echo Step 2
$BIN_DIR/removeExistingChipGenotypeLink.sh 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/removeExistingChipGenotypeLink.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 3
$BIN_DIR/genoexPSEsetup.sh 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 3"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/genoexPSEsetup.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 4
$BIN_DIR/mache705fileMitOriginalenDaten.sh 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/mache705fileMitOriginalenDaten.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 5
$BIN_DIR/trenneLabfilesNachIMPUTATIONsystem.sh 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 5"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/trenneLabfilesNachIMPUTATIONsystem.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 6
$BIN_DIR/fetchSingleGeneResultsFromFinalReport.sh 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 6"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/fetchSingleGeneResultsFromFinalReport.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 7
$BIN_DIR/storeNewDataIn705format.sh 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 7"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/storeNewDataIn705format.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 8
$BIN_DIR/sendInfoMailToContinue.sh 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 8"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/sendInfoMailToContinue.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 9
$BIN_DIR/sexCheck.sh 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 9"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/sexCheck.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 10
$BIN_DIR/checkIfArchiveGenotypeMatches.sh N 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 10"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/checkIfArchiveGenotypeMatches.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 11
$BIN_DIR/sendFinishingMailWOarg2.sh ${PROG_DIR}/${SCRIPT} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 11"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/sendFinishingMail.sh
        exit 1
fi
echo "----------------------------------------------------"
else
   echo "oops komisches Betriebssystem ich stoppe"
   $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/masterskriptHandleNewSNPdata.sh
   exit 1
fi
date
echo Ende ${SCRIPT}
