#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
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

##################################
echo Step 1
$BIN_DIR/MixNationalePedigrees.sh ${1} 2>&1  #> $LOG_DIR/MixNationalePedigrees.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/MixNationalePedigrees.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 2
$BIN_DIR/bauePedigreesUndReferenzfileID.sh $1 2>&1  #> $LOG_DIR/bauePedigreesUndReferenzfileID.${1}.log
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
$BIN_DIR/ableitenTypisierungsstatus.sh $1 2>&1  #> $LOG_DIR/ableitenTypisierungsstatus.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/ableitenTypisierungsstatus.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 5
$BIN_DIR/vergleicheAktuellenChipstatusMitPreviousRun.sh $1 2>&1  #> $LOG_DIR/vergleicheAktuellenChipstatusMitPreviousRun.${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 5"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/vergleicheAktuellenChipstatusMitPreviousRun.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 6
$BIN_DIR/checkTiereMitGenotypOhnePedigree.sh $1 2>&1 #> $LOG_DIR/checkTiereMitGenotypOhnePedigree.${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 6"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/checkTiereMitGenotypOhnePedigree.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 7
for chden in HD LD; do
$BIN_DIR/prepareMarkerfilesforPLINKAcrossAllChips.sh $1 ${chden} 2>&1  #> $LOG_DIR/prepareMarkerfilesforPLINKAcrossAllChips.${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 7"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/prepareMarkerfilesforPLINKAcrossAllChips.sh $1
        exit 1
fi
done
echo "----------------------------------------------------"
##################################
echo Step 8
if [ ${ReadGenotypes} == "A" ]; then
echo "Read SNPs from Archive: you can go out for a drink. I need several hours"
for chden in HD LD; do
nohup $BIN_DIR/fromArchivePrepareGenotypesforPLINKAcrossAllChips.sh $1 ${chden} 2>&1 > $LOG_DIR/prepareGenotypesforPLINKAcrossAllChips.${1}.${chden}.log &
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 8"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/fromArchivePrepareGenotypesforPLINKAcrossAllChips.sh $1
        exit 1
fi
done
fi
if [ ${ReadGenotypes} == "B" ]; then
echo "Read SNPs from ${oldrun} binary. -> I'm quite fast :-)"
for chden in HD LD; do
nohup $BIN_DIR/fromLastBinariesPrepareGenotypesforPLINKAcrossAllChips.sh $1 ${chden} 2>&1 > $LOG_DIR/prepareGenotypesforPLINKAcrossAllChips.${1}.${chden}.log &
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 8"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/fromLastBinariesPrepareGenotypesforPLINKAcrossAllChips.sh $1
        exit 1
fi
done
fi
echo "----------------------------------------------------"
sleep 300
##################################
echo Step 9
$BIN_DIR/waitTillGenotypesHaveBeenPrepared.sh $1 2>&1 #> $LOG_DIR/prepareGenotypesforPLINKAcrossAllChips.${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 9"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/waitTillGenotypesHaveBeenPrepared.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
sleep 60
echo Step 10
$BIN_DIR/linuxPLINKwiFIXSNP.sh $1 2>&1 #> $LOG_DIR/linuxPLINKwiFIXSNP.${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 10a"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/linuxPLINKwiFIXSNP.sh.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 12
$BIN_DIR/barplotSNPtrend.sh $1 2>&1 #> $LOG_DIR/2bstartePCA.${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 12"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/barplotSNPtrend.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
if [ ${1} == "BSW" ] || [ ${1} == "HOL" ]; then
echo Step 13
$BIN_DIR/prepareMatingsForRiskMatingPlot.sh -b $1 2>&1 #> $LOG_DIR/2bstartePCA.${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 13"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/prepareMatingsForRiskMatingPlot.sh $1
        exit 1
fi
echo "----------------------------------------------------"
fi
##################################
echo Step 14
$BIN_DIR/sendFinishingMail.sh $PROG_DIR/masterskriptMixIncomingWiExistingSNPndPrepPedi.sh $1 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 14"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh $1
        exit 1
fi
echo "----------------------------------------------------"
RIGHT_NOW=$(date)
echo $RIGHT_NOW Ende ${SCRIPT}
