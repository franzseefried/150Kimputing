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
  echo "Usage: $SCRIPT -s <string>"
  echo "  where <string> specifies the SNP giving a code from file ....."
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b:s: FLAG; do
  case $FLAG in
    b) # set option "b"
      export b=$(echo $OPTARG | awk '{print toupper($1)}')
      ;;
    s) # set option "s"
      export s=$(echo $OPTARG )
      re='^[0-9]+$'
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
if [ -z "${s}" ]; then
    usage 'Parameter for SNP must be specified using option -s <string>'      
fi


OS=$(uname -s)
if [ $OS != "Linux" ]; then
echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
$BIN_DIR/sendErrorMail.sh $PROG_DIR/${SCRIPT} ${1}
fi


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

##########################################################################################

#get Info about SNP from Reftab
getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colSCT=$colNr_
getColmnNr BTA ${REFTAB_SiTeAr} ; colBTA=$colNr_
getColmnNr MapBp ${REFTAB_SiTeAr} ; colBp=$colNr_
#define SNP
BTA=$(awk -v snp=${s} -v a=${colSCT} -v b=${colBTA} 'BEGIN{FS=";"}{if($a == snp) print $b}' ${REFTAB_SiTeAr})
Bp=$(awk -v snp=${s} -v a=${colSCT} -v b=${colBp} 'BEGIN{FS=";"}{if($a == snp) print $b}' ${REFTAB_SiTeAr})
echo $BTA
re='^[0-9]+$'
if ! [[ $BTA =~ $re ]] ; then 
    echo "Code for Chromosome is not a number: $BTA"
    $BIN_DIR/sendErrorMailWOarg2.sh ${SCRIPT}
    exit 1
fi
re='^[0-9]+$'
if ! [[ $Bp =~ $re ]] ; then 
    echo "Code for Basepair is not a number: $Bp"
    $BIN_DIR/sendErrorMailWOarg2.sh ${SCRIPT}
    exit 1
fi

echo $BTA $Bp $SNPbez

if ! test -s $WRK_DIR/${b}.${s}.lst ;then
   echo "$WRK_DIR/${b}.${s}.lst does not exist or has size zero"
   $BIN_DIR/sendErrorMailWOarg2.sh ${SCRIPT}
   exit 1
fi
#test if there is already a SNP with identical position in the dataset
uniKOORD=$((awk '{print $2,$3}' ${FIM_DIR}/${b}BTAwholeGenome_FImpute.snpinfo ;echo ${BTA} ${Bp})|awk 'a[$0]++{print "STOPP"}')
if [ ! -z ${uniKOORD} ]; then
   echo "OOOPS ${s} was nominated for singlegene imputation but there is a SNP already ind the dataset with identical position"
   exit 1
fi
##################################
echo Step 0
$BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh ${1} ${HIS_DIR}/${b}.RUN${run}.IMPresult.tierlis  2>&1 > $LOG_DIR/${SCRIPT}.${b}.${s}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_0"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
#urspruenhlich mal geplant aber es nie implementiert sindern wenn dann Genotypen aus dem Genotypenarchiv geholt mit extract.sh
#echo "Get test Results From Argus fuer ${s} und ${b}"
#$BIN_DIR/accessARGUS.sh -b ${b} -s ${s} # 2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${s}.log
#err=$(echo $?)
#if [ ${err} -gt 0 ]; then
#        echo "ooops Fehler SingleLocus_1"
#        $BIN_DIR/sendErrorMail.sh $BIN_DIR/accessARGUS.sh ${1}
#        exit 1
#fi
#echo "----------------------------------------------------"
##################################
echo "Adapt Fimpute Markermap and Genofile fuer ${s} und ${b}"
$BIN_DIR/adaptFimputeInputData.sh -b ${b} -c ${BTA} -p ${Bp} -s ${s}  2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${s}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/adaptFimputeInputData.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "run Fimpute SingleGeneImputation fuer $s $b"
$BIN_DIR/runningFimpute.sh -b ${b} -o genotypes -c ${BTA} -d ${s} -m "" 2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${s}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_3"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/runningFimpute.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Fetch SingeGeneImputationResult fuer $s $b"
$BIN_DIR/locateSingleGeneImputationResult.sh -b ${b} -c ${BTA} -s ${s} >> $LOG_DIR/${SCRIPT}.${b}.${s}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/locateSingleGeneImputationResult.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Plot Allelfrequency for ${s}"
$BIN_DIR/plotAlleleFreq.sh -b ${b} -d ${s} 2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${s}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_5"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/plotAlleleFreq.sh ${d}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Plot No. of Riskmatings for ${s}"
$BIN_DIR/plotNoOfRiskMatings.sh -b ${b} -d ${s} 2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${s}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_7"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/plotNoOfRiskMatings.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
if [ ${LogRRBAllelePot} == "Y" ]; then
echo "Plot LogRR & BAlleleFrq for ${s} in Population ${pp}"
$BIN_DIR/plotLogRRandBallele.sh -b ${b} -d ${s} -c HD -l ${IMPUTATIONFLAG} 2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${d}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/plotNoOfRiskMatings.sh ${d}
        exit 1
fi
echo "----------------------------------------------------"
fi
##################################
echo "send finishing mail"
$BIN_DIR/sendFinishingMail.sh $PROG_DIR/${SCRIPT}.sh ${s}
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_8"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
