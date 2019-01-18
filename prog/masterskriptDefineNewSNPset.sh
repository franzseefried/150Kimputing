#!/bin/bash
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo Start ${SCRIPT}
date

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
   $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/masterskriptHandleNewSNPdata.sh
elif [ ${ort} == "Linux" ]; then
##################################
echo Step 1
$BIN_DIR/writeNewAimMap.sh ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/writeNewAimMap.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 1
for chden in HD LD; do
$BIN_DIR/prepareMarkerfilesforPLINKAcrossAllChips.sh ${1} ${chden} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/prepareMarkerfilesforPLINKAcrossAllChips.sh
        exit 1
fi
echo "----------------------------------------------------"
done
##################################
echo Step 3
echo "Read SNPs from Archive: you can go out for a drink. I need several hours"
for chden in HD LD; do
nohup $BIN_DIR/fromArchivePrepareGenotypesforPLINKAcrossAllChips.sh $1 ${chden} 2>&1 > $LOG_DIR/prepareGenotypesforPLINKAcrossAllChips.${1}.${chden}.log &
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 3"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/fromArchivePrepareGenotypesforPLINKAcrossAllChips.sh $1
        exit 1
fi
done
sleep 300
##################################
echo Step 4
for chden in HD LD; do
$BIN_DIR/waitTillGenotypesHaveBeenPrepared.sh $1 2>&1 #> $LOG_DIR/prepareGenotypesforPLINKAcrossAllChips.${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/waitTillGenotypesHaveBeenPrepared.sh $1
        exit 1
fi
done
echo "----------------------------------------------------"
##################################
echo Step 5
$BIN_DIR/linuxPLINKselectSNP.sh ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 5"
        $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/linuxPLINKselectSNP.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 6
$BIN_DIR/linulinuxPLINKwiFIXSNP.sh ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 6"
        $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/linuxPLINKwiFIXSNP.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 7
$BIN_DIR/sendFinishingMailWOarg2.sh $PROG_DIR/masterskriptHandleNewSNPdata.sh 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 7"
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
