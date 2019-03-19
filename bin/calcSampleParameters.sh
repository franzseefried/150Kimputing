#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -t <string>"
  echo "  where <string> specifies the parameter for the TVD ID"
  echo "Usage: $SCRIPT -l <string>"
  echo "  where <string> specifies the name of the labfile to be checked"
  echo "Usage: $SCRIPT -d <string>"
  echo "  where <string> specifies the name of the folder where skript has to be started ou of"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :t:l:d: FLAG; do
  case $FLAG in
    t) # set option "t"
      export tvd=$(echo $OPTARG | awk '{print toupper($1)}')
      cle=$(echo ${tvd} | awk '{print length($1)}')
      if [ ${cle} != 14 ]; then
      echo "TVS was given as ${tvd} which is wrong since it does not count 14 bytes"
      exit 1
      fi
      ;;
    l) # set option "l"
      export labfile=$(echo $OPTARG )
      ;;
    d) # set option "d"
      export curdir=$(echo $OPTARG )
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that TVD is not empty
if [ -z "${tvd}" ]; then
      usage 'TVD not specified, must be specified using option -t <string>'   
fi
### # check that labefile is not empty
if [ -z "${labfile}" ]; then
    usage 'Parameter for labfile must be specified using option -l <string>'      
fi
### # check that labefile is not empty
if [ -z "${curdir}" ]; then
    usage 'Parameter for directory must be specified using option -d <string>'      
fi

##############################################################
cd ${curdir}
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit

OS=$(uname -s)
if [ $OS != "Linux" ]; then
echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
$BIN_DIR/sendErrorMail.sh $PROG_DIR/${SCRIPT} ${1}
exit 1
fi



nsnp=$(awk -v moggel=${tvd} 'BEGIN{FS=";"}{if ($2 == moggel) print $3}' $TMP_DIR/${labfile}.tvd | tee $TMP_DIR/${tvd}${labfile}GCforR | wc -l | awk '{print $1}')
awk -v moggel=${tvd} 'BEGIN{FS=";"}{if ($2 == moggel) print $4$5}' $TMP_DIR/${labfile}.tvd > $TMP_DIR/${tvd}${labfile}ABforR
#ls -trl $TMP_DIR/${tvd}${labfile}ABforR
Rscript ${BIN_DIR}/SNPeingangscheck.R ${PAR_DIR}/steuerungsvariablen.ctr.sh ${TMP_DIR}/${tvd}${labfile}ABforR ${TMP_DIR}/${tvd}${labfile}GCforR ${TMP_DIR}/${tvd}${labfile}SNPeingangscheck.out ${nsnp} 2>&1 > /dev/null &

    
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
