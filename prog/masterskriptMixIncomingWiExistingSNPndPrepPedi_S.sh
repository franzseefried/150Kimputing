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
echo Step 1
$BIN_DIR/MixNationalePedigrees.sh ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/MixNationalePedigrees.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 2
$BIN_DIR/bauePedigreesUndReferenzfileID.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/bauePedigreesUndReferenzfileID.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 3
$BIN_DIR/zusammenstellenFilemitBlutanteilen.sh ${1} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/zusammenstellenFilemitBlutanteilenForGCTAGenRelMat.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 4
$BIN_DIR/ableitenTypisierungsstatus.sh -b $1 -d ${IMPUTATIONFLAG}  2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/ableitenTypisierungsstatus.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 5
$BIN_DIR/vergleicheAktuellenChipstatusMitPreviousRun.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 5"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/vergleicheAktuellenChipstatusMitPreviousRun.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 6
$BIN_DIR/checkTiereMitGenotypOhnePedigree.sh -b $1 -d ${IMPUTATIONFLAG} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 6"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/checkTiereMitGenotypOhnePedigree.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 7
$BIN_DIR/writeNewAimMap.sh ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 7"
        $BIN_DIR/sendErrorMailWOarg2.sh $PROG_DIR/writeNewAimMap.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 8
for chden in HD LD; do
$BIN_DIR/prepareMarkerfilesforPLINKAcrossAllChips.sh -b $1 -c ${chden} -d ${IMPUTATIONFLAG} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 8"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/prepareMarkerfilesforPLINKAcrossAllChips.sh $1
        exit 1
fi
done
echo "----------------------------------------------------"
##################################
echo Step 9
echo "Read SNPs from Archive: you can go out for a drink. I need several hours"
for chden in HD LD; do
nohup $BIN_DIR/fromArchivePrepareGenotypesforPLINKAcrossAllChips.sh -b $1 -c ${chden} -d ${IMPUTATIONFLAG} 2>&1 > $LOG_DIR/prepareGenotypesforPLINKAcrossAllChips.${1}.${chden}.log &
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 9"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/fromArchivePrepareGenotypesforPLINKAcrossAllChips.sh $1
        exit 1
fi
done
sleep 300
##################################
echo Step 10
for chden in HD LD; do
$BIN_DIR/waitTillGenotypesHaveBeenPrepared.sh -b $1 -c ${chden} -d ${IMPUTATIONFLAG} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 10"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/waitTillGenotypesHaveBeenPrepared.sh $1
        exit 1
fi
echo "----------------------------------------------------"
done
##################################
echo Step 11
$BIN_DIR/linuxPLINKselectSNP.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 11"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/linuxPLINKselectSNP.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 12
$BIN_DIR/linuxPLINKwiFIXSNP.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 12"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/linuxPLINKwiFIXSNP.sh.sh $1
        exit 1
fi
##################################
echo Step 13
$BIN_DIR/barplotSNPtrend.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 13"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/barplotSNPtrend.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
if [ ${1} == "BSW" ] || [ ${1} == "HOL" ]; then
#echo Step 14
$BIN_DIR/prepareMatingsForRiskMatingPlot.sh -b $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 14"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/prepareMatingsForRiskMatingPlot.sh $1
        exit 1
fi
echo "----------------------------------------------------"
fi
##################################
echo Step 7
$BIN_DIR/sendFinishingMailWOarg2.sh ${PROG_DIR}/${SCRIPT} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 7"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/sendFinishingMail.sh
        exit 1
fi
echo "----------------------------------------------------"


date
echo Ende ${SCRIPT}
