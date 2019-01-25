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
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
elif [ ${1} == "BSW" ]; then
	echo $1 > /dev/null
elif [ ${1} == "HOL" ]; then
	echo $1 > /dev/null
else
	echo " $1 != BSW / HOL, ich stoppe"
	exit 1
fi

OS=$(uname -s)
if [ $OS != "Linux" ]; then
echo "falsches Betriebssystem"
$BIN_DIR/sendErrorMail.sh $PROG_DIR/${SCRIPT} ${1}
exit 1
fi
#check if parameter vor no of prll jobs was given
if [ -z ${numberOfParallelHAPLOTYPEJobs} ] ;then
echo "numberOfParallelHAPLOTYPEJobs is missing which is not allowed. Check ${lokal}/parfiles/steuerungsvariablen.ctr.sh"
exit 1
fi
#check if parameter vor no of prll jobs was given
if [ -z ${numberOfParallelSIGEIMPJobs} ] ;then
echo "numberOfParallelSIGEIMPJobs is missing which is not allowed. Check ${lokal}/parfiles/steuerungsvariablen.ctr.sh"
exit 1
fi
set -o errexit
set -o nounset
##########################################################################################
echo "Clean Directoy"
#no matter about breeds this is regulated below by giving shortcuts during single gene imputation
$BIN_DIR/cleanUpSingleGeneFilesIfTheyExist.sh ${1} HD ${dd} 2>$1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 0"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/extractSNPsForSingleGeneImputation.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##########################################################################################
echo "Exctract for some SNPs the results from Chipdata any paramaters are given in ${REFTAB_SiTeAr}"
#no matter about breeds this is regulated below by giving shortcuts during single gene imputation
for dd in HD LD; do
$BIN_DIR/extractSNPsForSingleGeneImputation.sh ${1} ${dd} 2>$1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 0"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/extractSNPsForSingleGeneImputation.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
done
##########################################################################################
echo "Run Fimpute Genomewide safe haplotypes ${1}"
$BIN_DIR/runningFimputeGENOMEwideSafeHaplotypes.sh ${1} 2>$1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        exit 1
fi
echo "----------------------------------------------------"
##########################################################################################
echo "Check if Fimpute haplotypes are ready $1"
$BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh ${1} ${FIM_DIR}/${1}BTAwholeGenome.haplos/genotypes_imp.txt 2>$1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        exit 1
fi
echo "----------------------------------------------------"
##########################################################################################
echo "Grep relevant BTAs for $1"
$BIN_DIR/grepRelevantBTA.sh ${1} SINGLEGENE 2>$1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2b"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/grepRelevantBTA.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
if [ ${1} == "BSW" ] || [ ${1} == "HOL" ]; then
  BTA=$(cat $TMP_DIR/${breed}.relevantBTAs.forSingleGeneImputation.txt)
fi
##################################
echo "Markermap(s) now for $1 und Single GeneImputation"
for chromo in $(echo $BTA ); do
$BIN_DIR/fastFimputeMarkermap-prepBTAwise.sh ${1} ${chromo} 2>&1 #> $LOG_DIR/FimputeMarkermap-prepBTAwise.${1}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 3"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/fastFimputeMarkermap-prepBTAwise.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
done
##################################
echo "Genotypefile(s) now for $1 und Single GeneImputation"
for chromo in $(echo $BTA ); do
$BIN_DIR/fastFimputeGeno-prepBTAwise.sh ${1} ${chromo} 2>&1 #> $LOG_DIR/FimputeGeno-prepBTAwise.${1}.${chromo}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/FimputeGeno-prepBTAwise.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
done
##########################################################################################
echo "Grep relevant BTAs for HAPLOTYPE $1"
$BIN_DIR/grepRelevantPredictions.sh ${1} HAPLOTYPE 2>$1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2b"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/grepRelevantPredictions.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Call distinct Haplotypes for ${1}"
runsHH=$(echo $TMP_DIR/${breed}.HAPLOTYPE.selected)
if [ ! -z "${runsHH}" ]; then
pids=
nJobs=0
for locus in ${runsHH[@]}; do
ch=$(echo ${locus} | cut -d'-' -f1)
  while [ $nJobs -ge ${numberOfParallelHAPLOTYPEJobs} ]; do
    pids_old=${pids[@]}
    pids=
    nJobs=0
    for pid in ${pids_old[@]}; do
      if kill -0 $pid > /dev/null 2>&1; then # kill -0 $pid ist true falls der Job noch laeuft
        nJobs=$(($nJobs+1))
        pids=(${pids[@]} $pid)
      fi
    done
    sleep 10
  done
  (
  echo -c ${ch} -d ${locus}
  $BIN_DIR/SingleLocusHaplotyping.sh -b ${1} -d ${locus} 2>&1
  )&
  pid=$!
# echo $pid
  pids=(${pids[@]} $pid)
  nJobs=$(($nJobs+1))
done
else
  echo "${runsHH} was empty"
fi
#sonderfall BLG_AA: eigentlich 2 SNP die aber laut paper in vollem LD sind. Es genügt nur einen zu typisieren. ausserdem haben wir nur die Genotypen AA AB und BB in ARGUS.Seltenere Proteintypen unterscheiden wir nicht
##########################################################################################
echo "Grep relevant Predictionss for SINGLEGENE $1"
$BIN_DIR/grepRelevantPredictions.sh ${1} SINGLEGENE 2>$1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2b"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/grepRelevantPredictions.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
runsGI=$(echo $TMP_DIR/${breed}.SINGLEGENE.selected)
if [ ! -z "${runsGI}" ]; then
#runsGI="CSN2_AB CSN2_A1A2 BLG_AA"
pids=
pids=
nJobs=0
for locus in ${runsGI[@]}; do
  while [ $nJobs -ge ${numberOfParallelSIGEIMPJobs} ]; do
    pids_old=${pids[@]}
    pids=
    nJobs=0
    for pid in ${pids_old[@]}; do
      if kill -0 $pid > /dev/null 2>&1; then # kill -0 $pid ist true falls der Job noch laeuft
        nJobs=$(($nJobs+1))
        pids=(${pids[@]} $pid)
      fi
    done
    sleep 10
  done
  (
  echo -s ${locus}
  $BIN_DIR/SingleGeneImputation.sh -b ${$1} -s ${locus} 2>&1
  )&
  pid=$!
# echo $pid
  pids=(${pids[@]} $pid)
  nJobs=$(($nJobs+1))
done
fi
##########################################################################################
echo "Grep relevant Predictions for GENOMEWIDE which means causal variants which are included in Genomewide Imputation $1"
$BIN_DIR/grepRelevantPredictions.sh ${1} GENOMEWIDE 2>$1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2b"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/grepRelevantPredictions.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
runsGW=$(echo $TMP_DIR/${breed}.GENOMEWIDE.selected)
if [ ! -z "${runsGW}" ]; then
pids=
pids=
nJobs=0
for locus in ${runsGI[@]}; do
  while [ $nJobs -ge ${numberOfParallelSIGEIMPJobs} ]; do
    pids_old=${pids[@]}
    pids=
    nJobs=0
    for pid in ${pids_old[@]}; do
      if kill -0 $pid > /dev/null 2>&1; then # kill -0 $pid ist true falls der Job noch laeuft
        nJobs=$(($nJobs+1))
        pids=(${pids[@]} $pid)
      fi
    done
    sleep 10
  done
  (
  echo -s ${locus}
  $BIN_DIR/PullVariantFromGenomewideSystem.sh -b ${$1} -s ${locus} 2>&1
  )&
  pid=$!
# echo $pid
  pids=(${pids[@]} $pid)
  nJobs=$(($nJobs+1))
done
fi
###########################################
#echo "Run severalSNPs SingleGeneImputatuion for BV"
#runsSGI="Kappa_Casein"
#pids=
#pids=
#nJobs=0
#for lcu in ${runsSGI[@]}; do
#  while [ $nJobs -ge ${numberOfParallelSIGEIMPJobs} ]; do
#    pids_old=${pids[@]}
#    pids=
#    nJobs=0
#    for pid in ${pids_old[@]}; do
##      if kill -0 $pid > /dev/null 2>&1; then # kill -0 $pid ist true falls der Job noch laeuft
 #       nJobs=$(($nJobs+1))
#        pids=(${pids[@]} $pid)
#      fi
#    done
#    sleep 10
#  done
#  (
#  echo -d ${lcu}
#  $PROG_DIR/masterskriptSingleGeneImputation_MoreThanOneSNP.sh -b BSW -s ${lcu} -p BV 2>&1
#  )&
#  pid=$!
## echo $pid
#  pids=(${pids[@]} $pid)
#  nJobs=$(($nJobs+1))
#done
##########################################################################################
echo "Grep relevant Predictions for SVM $1"
$BIN_DIR/grepRelevantPredictions.sh ${1} SVM 2>$1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2b"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/grepRelevantPredictions.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
#############################################
echo "RUN SVMbased RYF Prediction for ${1}"
runSVM=$(echo $TMP_DIR/${breed}.SVM.selected)
if [ ! -z "${runsSVM}" ]; then
pids=
nJobs=0
for svmlc in ${runsSVM[@]}; do
ch=$(echo ${svmlc} | cut -d'-' -f1)
  while [ $nJobs -ge ${numberOfParallelHAPLOTYPEJobs} ]; do
    pids_old=${pids[@]}
    pids=
    nJobs=0
    for pid in ${pids_old[@]}; do
      if kill -0 $pid > /dev/null 2>&1; then # kill -0 $pid ist true falls der Job noch laeuft
        nJobs=$(($nJobs+1))
        pids=(${pids[@]} $pid)
      fi
    done
    sleep 10
  done
  (
  echo -c ${ch} -d ${locus}
  $PROG_DIR/masterskriptSVMbasedGenotypePredictionRYF.sh -b BSW -c ${ch} -d ${svmlc} -p BV 2>&1
  )&
  pid=$!
# echo $pid
  pids=(${pids[@]} $pid)
  nJobs=$(($nJobs+1))
done
#############################################
echo "RUN SVMbased Prediction for BV and OB together"
runsSVM=$(echo ${runsSVMBSW})
pids=
nJobs=0
for svmlc in ${runsSVM[@]}; do
  while [ $nJobs -ge ${numberOfParallelHAPLOTYPEJobs} ]; do
    pids_old=${pids[@]}
    pids=
    nJobs=0
    for pid in ${pids_old[@]}; do
      if kill -0 $pid > /dev/null 2>&1; then # kill -0 $pid ist true falls der Job noch laeuft
        nJobs=$(($nJobs+1))
        pids=(${pids[@]} $pid)
      fi
    done
    sleep 10
  done
  (
  echo -c ${ch} -d ${locus}
  $BIN_DIR/SVMbasedGenotypePrediction.sh -b ${1} -d ${svmlc} 2>&1
  )&
  pid=$!
# echo $pid
  pids=(${pids[@]} $pid)
  nJobs=$(($nJobs+1))
done
fi
##################################
echo "send finishing mail"
$BIN_DIR/sendFinishingMail.sh $PROG_DIR/${SCRIPT} $1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 10"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh ${d}
        exit 1
fi
echo "----------------------------------------------------"



echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}