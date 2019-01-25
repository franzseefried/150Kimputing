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
    usage 'Parameter for the polymophism must be specified using option -z <string>'      
fi

OS=$(uname -s)
if [ $OS != "Linux" ]; then
echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
$BIN_DIR/sendErrorMail.sh $PROG_DIR/${SCRIPT} ${1}
fi

##################################
echo Step 0
$BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh ${1} ${HIS_DIR}/${b}.RUN${run}.IMPresult.tierlis  2>&1 > $LOG_DIR/${SCRIPT}.${b}.${d}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_0"
        $BIN_DIR/sendErrorMailWOarg2.sh $BIN_DIR/waitTillFileInARG2HasBeenPrepared.sh
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Call ${d} Haplotyp ${b} and compare with previous run"
$BIN_DIR/findHaplotypeCarrier.sh -b ${b} -d ${d} 2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${d}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/findHaplotypeCarrierAusFImpute.sh ${d}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Plot Allelfrequency for ${d}"
$BIN_DIR/plotAlleleFreq.sh -b ${b} -d ${d} 2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${d}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/plotAlleleFreq.sh ${d}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Plot No. of Riskmatings for ${d} in Population ${pp}"
$BIN_DIR/plotNoOfRiskMatings.sh -b ${b} -d ${d} 2>&1 >> $LOG_DIR/${SCRIPT}.${b}.${d}.log
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_3"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/plotNoOfRiskMatings.sh ${d}
        exit 1
fi
echo "----------------------------------------------------"
#echo "Log file from ${b} ${c} ${d} from next record on" >> $LOG_DIR/9masterskriptFimputeRunExplicit_${b}.log
#cat $LOG_DIR/${SCRIPT}.${b}.${d}.log >> $LOG_DIR/9masterskriptFimputeRunExplicit_${b}.log
#echo "Log file from ${b} ${c} ${d} till here" >> $LOG_DIR/9masterskriptFimputeRunExplicit_${b}.log
##################################
echo "send finishing mail"
$BIN_DIR/sendFinishingMail.sh $PROG_DIR/${SCRIPT}.sh ${d}
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler SingleLocus_5"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh ${d}
        exit 1
fi
echo "----------------------------------------------------"


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
