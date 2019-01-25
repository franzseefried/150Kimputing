#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options bsw, hol or vms"
  echo "Usage: $SCRIPT -d <string>"
  echo "  where <string> specifies the Haplotype to be analyzed, e.g. 7-40-44 for BTA7 from 40 to 44 MB"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b:d: FLAG; do
  case $FLAG in
    b) # set option "b"
      export b=$(echo $OPTARG | awk '{print toupper($1)}')
      ;;
    d) # set option "d"
      export d=$(echo $OPTARG)
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that breed is not empty
if [ -z "${b}" ]; then
      usage 'BREED not specified, must be specified using option -b <string>'   
fi
### # check that setofanomals is not empty
if [ -z "${d}" ]; then
    usage 'Parameter for the Genetic Variant must be specified using option -d <string>'      
fi

OS=$(uname -s)
if [ $OS != "Linux" ]; then
echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
$BIN_DIR/sendErrorMail.sh $PROG_DIR/${SCRIPT} ${1}
fi
set -o nounset
set -o errexit

##########################################################################################
# Funktionsdefinition

# Funktion gibt Spaltennummer gemaess Spaltenueberschrift in csv-File zurueck.
# Es wird erwartet, dass das Trennzeichen das Semikolon (;) ist
getColmnNr () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(head -1 $2 | tr ';' '\n' | grep -n "^$1$" | awk -F":" '{print $1}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}
#######################################################################################
#Definition des Bereichs. Ausgehend von der Position in der referenzliste +/- 3 Mb
#get Info about SNP from Reftab
getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colSCT=$colNr_
getColmnNr BTA ${REFTAB_SiTeAr} ; colBTA=$colNr_
getColmnNr MapBp ${REFTAB_SiTeAr} ; colBp=$colNr_
#define SNP
BTA=$(awk -v snp=${d} -v a=${colSCT} -v b=${colBTA} 'BEGIN{FS=";"}{if($a == snp) print $b}' ${REFTAB_SiTeAr})
Bp=$(awk -v snp=${d} -v a=${colSCT} -v b=${colBp} 'BEGIN{FS=";"}{if($a == snp) print $b}' ${REFTAB_SiTeAr})
echo $BTA $Bp $d

if ! test -s $WRK_DIR/${b}_Referenzgenotypes_${d}.txt ;then
   echo "$WRK_DIR/${b}_Referenzgenotypes_${d}.txt does not exist or has size zero"
   $BIN_DIR/sendErrorMailWOarg2.sh ${SCRIPT}
   exit 1
fi

##################################
echo Step 0
$BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh ${b} ${FIM_DIR}/${b}BTAwholeGenome.out/genotypes_imp.txt 2>&1 > $LOG_DIR/${SCRIPT}.${b}.${d}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SVMGenotypePrediction_0"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Hole Imputationsergebnis ${d} Haplotyp ${b}"
$BIN_DIR/modImputationResultForSVMPredcition.sh -b ${b} -d ${d} 2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${d}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SVMGenotypePrediction_1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/modImputationResultForSVMPredcition.sh ${d}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Call genotypes ${d} using SVM for ${b}"
$BIN_DIR/callSVMgenotypes.sh -b ${b} -d ${d} -v ${ParCrossVal} 2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${d}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SVMGenotypePrediction_2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/callSVMgenotypes.sh ${d}
        exit 1
fi
echo "----------------------------------------------------"
###################################
echo "Plot Allelfrequency for ${d} in ${b}"
$BIN_DIR/plotAlleleFreq.sh -b ${b} -d ${d} 2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${d}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SVMGenotypePrediction_4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/plotAlleleFreq.sh ${d}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Plot No. of Riskmatings for ${d} in ${b}"
$BIN_DIR/plotNoOfRiskMatings.sh -b ${b} -d ${d} 2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${d}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_5"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/plotNoOfRiskMatings.sh ${d}
        exit 1
fi
echo "---------------------------------------------------"
##################################
echo "Log file from ${b} ${d} from next record on" >> $LOG_DIR/9masterskriptFimputePrepAndRunBTAwise_${b}.log
cat $LOG_DIR/${SCRIPT}.${b}.${d}.log >> $LOG_DIR/9masterskriptFimputePrepAndRunBTAwise_${b}.log
echo "Log file from ${b} ${d} till here" >> $LOG_DIR/9masterskriptFimputePrepAndRunBTAwise_${b}.log
##################################
echo "send finishing mail"
$BIN_DIR/sendFinishingMail.sh $PROG_DIR/${SCRIPT}.sh ${d}
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SVMGenotypePrediction_5"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh ${d}
        exit 1
fi
echo "----------------------------------------------------"


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
