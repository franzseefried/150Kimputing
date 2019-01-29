#!/bin/bash
SCRIPT=`basename ${BASH_SOURCE[0]}`
RIGHT_NOW=$(date)
echo RIGHT_NOW Start ${SCRIPT}
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


#check Server
ort=$(uname -a | awk '{print $1}' )
if  [ ${ort} == "Darwin" ]; then
   echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
   $BIN_DIR/sendErrorMail.sh ${SCRIPT} $1
elif [ ${ort} == "Linux" ]; then
##################################
$BIN_DIR/MASK5percentYoungestHDtoLd.sh ${1} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/MASK5percentYoungestHDtoLd.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
$BIN_DIR/MASKstelleTypisierungssituationVonVundMundMVauf.sh ${1} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/MASKstelleTypisierungssituationVonVundMundMVauf.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
$BIN_DIR/runningFimpute.sh -b ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 3"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/MASKrunningFimputeGENOMEwide.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
$BIN_DIR/MASKschreibeListenueberImputationsergebnis.sh -b ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 3"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/MASKschreibeListenueberImputationsergebnis.sh $1
        exit 1
fi
echo "----------------------------------------------------"
echo "any evaluation of the imputation accuracy is done by Mirjam spenegeler"
##################################
echo "send finishing mail"
$BIN_DIR/sendFinishingMail.sh ${SCRIPT} $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh $1
        exit 1
fi
echo "----------------------------------------------------"
else
   echo "komisches Betriebssystem ich stoppe"
   $BIN_DIR/sendErrorMail.sh ${SCRIPT} $1
   exit 1
fi
echo " "
RIGHT_END=$(date)
echo RIGHT_END Ende ${SCRIPT}
