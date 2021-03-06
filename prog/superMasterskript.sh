#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
cd /qualstore03/data_zws/snp/150Kimputing
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
if [ ${dbsystem} != "rapid" ]; then
   DEUTZ_DIR=/qualstororatest01/argus_${dbsystem}
fi

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
echo Step 0
$BIN_DIR/testParameters.sh ${1} 2>&1 > ${LOG_DIR}/0testParameters_${1}.log 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 0"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/testParameters.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 1
$PROG_DIR/masterskriptMixIncomingWiExistingSNPndPrepPedi_${snpstrat}.sh ${1} 2>&1 > ${LOG_DIR}/1masterskriptMixIncomingWiExistingSNPndPrepPedi_${1}.log 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 1"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptMixIncomingWiExistingSNPndPrepPedi.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 2
$PROG_DIR/masterskriptFimputePrepGenomwide.sh ${1} 2>&1 > ${LOG_DIR}/2masterskriptFimputePrepGenomwide_${1}.log  
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 2"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptFimputePrepGenomwide.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 3
nohup $PROG_DIR/masterskriptSNPrelshipAnalysesPAIRWISE.sh ${1} 2>&1 > ${LOG_DIR}/3masterskriptSNPrelshipAnalyses_${1}.log &
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 3"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptVVMVcheck.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 4
$PROG_DIR/masterskriptPedigreePlausi.sh ${1} 2>&1 > ${LOG_DIR}/4masterskriptPedigreePlausi_${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 4"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptPedigreePlausi.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 5
$PROG_DIR/masterskriptTWINcheck.sh ${1} 2>&1 > ${LOG_DIR}/5masterskriptTWINcheck_${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 5"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptTWINcheck.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 6
nohup $PROG_DIR/masterskriptSNP1101Inbreeding.sh ${1} 2>&1 > ${LOG_DIR}/6masterskriptSNP1101Inbreeding_${1}.log &
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 6"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptFetchGenomicFcoefficient.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 7
$PROG_DIR/masterskriptFimputeRunStandard.sh ${1} 2>&1 > ${LOG_DIR}/7masterskriptFimputeRunStandard_${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 7"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptFimputeRunStandard.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 8
$PROG_DIR/masterskriptWriteLogfiles.sh ${1} 2>&1 > ${LOG_DIR}/8masterskriptWriteLogfiles_${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 8"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptWriteLogfiles.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 8b
MitEinzelgen=N
$PROG_DIR/masterskriptScreenLogfilesFast.sh ${1} ${MitEinzelgen} 2>&1 > ${LOG_DIR}/13masterskriptScreenLogfilesFast_${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 8b"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptScreenLogfilesFast.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
$BIN_DIR/sendInfoMailToStartPrediction.sh ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 8b"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/sendInfoMailToStartPrediction.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
if [ ${1} == "BSW" ] || [ ${1} == "HOL" ] ; then
echo Step 9
nohup $PROG_DIR/masterskriptFimputeRunExplicit.sh ${1} 2>&1 > ${LOG_DIR}/9masterskriptFimputeRunExplicit_${1}.log 2>&1 &
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 9"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptFimputeRunExplicit.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
fi
##################################
echo Step 10
cd ../einzelgen
prog/masterskriptProcessDataFiles.sh -b ${1} 2>&1 > ${LOG_DIR}/10masterskriptEinzelgenPipeline_${1}.log 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        cd ../150Kimputing
        echo "ooops Fehler superMasterskript 10"
        $BIN_DIR/sendErrorMail.sh einzelgen/masterskriptProcessDataFiles.sh $1
        exit 1
fi
prog/masterskriptBringResultsToCustomers.sh -b ${1} 2>&1 >> ${LOG_DIR}/10masterskriptEinzelgenPipeline_${1}.log 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        cd ../150Kimputing
        echo "ooops Fehler superMasterskript 10"
        $BIN_DIR/sendErrorMail.sh einzelgen/masterskriptProcessDataFiles.sh $1
        exit 1
fi
cd ${lokal}
echo "----------------------------------------------------"
##################################
if [ ${evalImpAcc} == "Y" ];then
echo Step 11
nohup $PROG_DIR/masterskriptImputationAccuracy.sh ${1} 2>&1 > ${LOG_DIR}/12masterskriptImputationAccuracy_${1}.log &
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 11"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptScreenLogfilesFast.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
fi
##################################
#this step is additional and helpfull when you want to clarify unclear MGS issues
echo Step 12
$PROG_DIR/masterskriptGPsearch1.sh ${1} 2>&1 > ${LOG_DIR}/14masterskriptGPsearch1_${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 12"
        $BIN_DIR/sendErrorMail.sh $PROG_DIR/masterskriptGPsearch1.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
if [ ${1} != "VMS" ] && [ ${HDfollows} == "Y" ]; then
  echo "Baue Startfile fuer HDimputing auf $1"
  $BIN_DIR/quickVerarbeiteGENOMEwide-imputierte-TiereAlsStartfuerHDimputing.sh ${1} 2>&1
  err=$(echo $?)
  if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 13"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/quickVerarbeiteGENOMEwide-imputierte-TiereAlsStartfuerHDimputing.sh $1
        exit 1
  fi
  echo Step 14 *****°°°°°Run HD Imputation via superMasterskript°°°°°*****
  cd ${secondIMPUTATIONDIR}
  nohup prog/superMasterskript.sh ${1} 2>&1 > log/superMasterskript_${1}.log &
  cd ${MAIN_DIR}
  err=$(echo $?)
  if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 18"
        $BIN_DIR/sendErrorMail.sh ${secondIMPUTATIONDIR} prog/superMasterskript.sh $1
        exit 1
  fi
  echo "----------------------------------------------------"
  else
  echo " "
  echo "No second imputation will follow"
fi
##################################
echo Step 15
$BIN_DIR/sendFinishingMailWOarg2.sh ${PROG_DIR}/${SCRIPT}
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler superMasterskript 14"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/sendFinishingMail.sh
        exit 1
fi
echo "----------------------------------------------------"
echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
