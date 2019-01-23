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
	echo " $1 != BSW / HOL, ich stoppe"
	exit 1
fi


#check Server
ort=$(uname -a | awk '{print $1}' )
if  [ ${ort} == "Darwin" ]; then
   echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
   $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptFimputeRunAndControlGenomwide.sh $1
elif [ ${ort} == "Linux" ]; then
##################################
echo "Anaylsiere Typisierunssituation fuer $1"
$BIN_DIR/stelleTypisierungssituationVonVundMundMVauf.sh ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/stelleTypisierungssituationVonVundMundMVauf.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Run FImpute now for $1"
$BIN_DIR/runningFimputeGENOMEwide.sh ${1} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/runningFimputeGENOMEwide.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Check No. of missmatches FImpute now for $1"
$BIN_DIR/checkFImputeParentageMissmatches.sh ${1} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 3"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/checkFImputeParentageMissmatches.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Make lists for imputation result now for $1"
$BIN_DIR/schreibeListenueberImputationsergebnis.sh ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/schreibeListenueberImputationsergebnis.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Compare Imputation result with last result for $1"
$BIN_DIR/vergleiche2ImputationRunsWithSimilarSNPsetAndMap.sh ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 5"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/vergleiche2ImputationRunswiFIXSNP.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
if [ ${EFFESTfollows} == "Y" ]; then
echo "Prepare Imputationresult fuer GenSel for $1"
$BIN_DIR/verarbeiteGENOMEwide-imputierte-TiereFuerGenSel.sh -b ${1} -c ${minchipstatus} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 8"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/verarbeiteGENOMEwide-imputierte-TiereFuerGenSel.sh $1
        exit 1
fi
echo "----------------------------------------------------"
fi
##################################
echo "send finishing mail"
$BIN_DIR/sendFinishingMail.sh $PROG_DIR/masterskriptFimputeRunAndControlGenomwideQUICK.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 11"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh $1
        exit 1
fi
echo "----------------------------------------------------"
else
   echo "komisches Betriebssystem ich stoppe"
   $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptFimputeRunAndControlGenomwide.sh $1
fi



echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
