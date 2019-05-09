#!/bin/bash
RIGHT_NOW=$(date )
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
  echo "Usage: $SCRIPT -s <string>"
  echo "  where <string> specifies the SNP to be extracted"
  exit 1
}


outtime=$(date +"%x" | awk 'BEGIN{FS="/"}{print $2$1$3}')

while getopts :s: FLAG; do
  case $FLAG in
    s) # set option "p"
      SNP=$(echo $OPTARG | tr a-z A-Z)
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
### # check that parent is not empty
if [ -z "${SNP}" ]; then
    usage 'SNP name must be specified using option -s <string>'      
fi

#######Funktionsdefinition
getColmnNrSemicl () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(head -1 $2 | tr ';' '\n' | grep -n "^$1$" | awk -F":" '{print $1}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}
##########################

set -o nounset
set -o errexit



echo $SNP


echo " "
echo "Extracting SNP ${SNP} starts now "
echo " "
pids=
for labfile in $(ls $BCP_DIR/${run}/binaryfiles/*150K*.bed) ; do
#(
  bfileloc=$(basename ${labfile})
  chip=$(echo ${bfileloc} | cut -d'.' -f2)
  bshort=$(echo $labfile | sed 's/\.bed//g')
  echo $labfile $chip
 
  #aufbau mapfile
  echo "${SNP}" > ${TMP_DIR}/${SNP}.keep
  echo "$SNP B" > ${TMP_DIR}/${SNP}.keep.force.Bcount
  #cat ${TMP_DIR}/${SNP}.keep	
  $FRG_DIR/plink --bfile ${bshort} --missing-genotype '0' --cow --nonfounders --noweb --extract $TMP_DIR/${SNP}.keep --recodeA --reference-allele ${TMP_DIR}/${SNP}.keep.force.Bcount --out $TMP_DIR/${SNP}.${chip} 
#)
done




echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
