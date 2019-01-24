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

b=$1

#check Server
ort=$(uname -a | awk '{print $1}' )
if  [ ${ort} == "Darwin" ]; then
   echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
   $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptHandleNewSNPdata.sh
elif [ ${ort} == "Linux" ]; then
##################################
echo Step 0
$BIN_DIR/waitTillImputationIsReadyToWriteLogfiles.sh ${b}  2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/waitTillImputationIsReadyToWriteLogfiles.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 1
for d in HD LD; do 
$BIN_DIR/writeListOfIntergenomicsNdCDCBsnp.sh ${b} ${d} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/writeListOfIntergenomicsNdCDCBsnp.sh ${b}
        exit 1
fi
done
echo "----------------------------------------------------"
##################################
echo Step 2
$BIN_DIR/prepareRequiredFilesForSettingUpLogfile.sh ${b} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/prepareRequiredFilesForSettingUpLogfile.sh ${b}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 3
$BIN_DIR/makeONElogfileForZOs.sh ${b} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 3"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/makeONElogfileForZOs.sh ${b}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 4
$BIN_DIR/prepareRequiredFilesForSettingUpSumUpfile.sh ${b} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/prepareRequiredFilesForSettingUpSumUpfile.sh ${b}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 5
$BIN_DIR/sumUpOverallLOGfile.sh ${b} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 5"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sumUpOverallLOGfile.sh  ${b}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 6
$BIN_DIR/compareSumUpcsvsWithLastRun.sh ${b}  2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 6"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sumUpOverallLOGfile.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 7
$BIN_DIR/giveSummaryAboutNewlyAddedSamplesInTermsOfTheirLogfileContent.sh ${b}  2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 7"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/giveSummaryAboutNewlyAddedSamplesInTermsOfTheirLogfileContent.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 8
$BIN_DIR/writeReportForRouineExternalSamples.sh ${b}  2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 7"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/writeReportForRouineExternalSamples.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 9
$BIN_DIR/masterskriptAttentionMail.sh ${b}  2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 9"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/masterskriptAttentionMail.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 9
$BIN_DIR/masterskriptAttentionMail2.sh ${b}  2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 9"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/masterskriptAttentionMail2.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
#if [ ${b} == "BSW" ] || [ ${b} == "HOL" ]; then
#echo Step 8
#nohup $BIN_DIR/fetchSNPrelshipVsALLforForALLAnimalsWithSuspiciousMVcheckORPedigreeProblems.sh ${b}  2>&1 &
#err=$(echo $?)
#if [ ${err} -gt 0 ]; then
#        echo "ooops Fehler 7"
#        $BIN_DIR/sendErrorMail.sh $BIN_DIR/fetchSNPrelshipVsALLforForALLAnimalsWithSuspiciousMVcheckORPedigreeProblems.sh
#        exit 1
#fi
#echo "----------------------------------------------------"
#fi
##################################
echo Step 8
$BIN_DIR/sendFinishingMail.sh $PROG_DIR/masterskriptWriteLogfiles.sh ${b} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 8"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh
        exit 1
fi
echo "----------------------------------------------------"
else
   echo "oops komisches Betriebssystem ich stoppe"
   $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptWriteLogfiles.sh
   exit 1
fi
echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
