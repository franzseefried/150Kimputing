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
  echo "Usage: $SCRIPT -a <string>"
  echo "  where <string> specifies the animal given by 14bytes TVD"
  echo "Usage: $SCRIPT -s <string>"
  echo "  where <string> specifies the SNP to be extracted"
  exit 1
}


outtime=$(date +"%x" | awk 'BEGIN{FS="/"}{print $2$1$3}')

while getopts :a:s: FLAG; do
  case $FLAG in
    a) # set option "a"
      SAMPLE=$(echo $OPTARG | tr a-z A-Z)
      ;;
    s) # set option "p"
      SNP=$(echo $OPTARG | tr a-z A-Z)
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
### # check that breed is not empty
if [ -z "${SAMPLE}" ]; then
      usage 'Animal not specified, must be specified using option -a <string>'   
fi
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



echo $SAMPLE $SNP

#holen der IDSAMPLE
IDSAMPLE=$(awk -v ss=${SAMPLE} 'BEGIN{FS=";"}{if($2 == ss) print $1}' $WORK_DIR/animal.overall.info)
if test -z ${IDSAMPLE}; then
echo "IDSAMPLE ${SAMPLE} not in $WORK_DIR/animal.overall.info"
exit 1
fi

#pruefen ob genotypisiert
for s in ${IDSAMPLE}; do
n=$(ls -trl $SNP_DIR/dataWide*/*/${s}.lnk | wc -l)
if [ ${n} -gt 0 ]; then
echo ok > /dev/null
else
echo "$s has nor genotype link"
exit 1
fi
done

nS=$(ls $SNP_DIR/dataWide*/*/${IDSAMPLE}.lnk )
echo $nS
echo " "
echo "Extracting SNP ${SNP} starts now for ${IDSAMPLE}."
echo " "
pids=
for labfile in ${nS} ; do
#(
  errorcounterTIER=0
  fileloc=$(ls -trl   ${labfile} | awk '{print $11}')
  bfileloc=$(basename ${fileloc})
  chip=$(echo ${fileloc} | cut -d'/' -f5 | sed 's/dataWide//g')
  #echo $labfile $fileloc $chip
 
  #aufbau mapfile
  getColmnNrSemicl QuagCode ${REFTAB_CHIPS}; colCC=${colNr_};
  getColmnNrSemicl IntergenomicsCode ${REFTAB_CHIPS}; colDD=${colNr_};
  intname=$(awk -v cc=${colCC} -v dd=${colDD} -v ee=${chip} 'BEGIN{FS=";"}{if( $cc == ee ) print $dd }' ${REFTAB_CHIPS})
  awk '{ sub("\r$", ""); print }' $MAP_DIR/intergenomics/SNPindex_${intname}_new_order.txt | sed 's/Dominant Red/Dominant_Red/g' | awk '{if($3 > 30) print "30",toupper($1),"0",$4;else print $3,toupper($1),"0",$4}' > $TMP_DIR/${IDSAMPLE}.${bfileloc}.map
  #aufbau pedfile
  cat ${fileloc} | sed 's/ /o /1' | sed 's/ / 0 0 9 9 /1' | sed 's/^/1 /g' > $TMP_DIR/${IDSAMPLE}.${bfileloc}.ped

  #schneiden des nachgefragten SNP
  nC=$(awk -v marker=${SNP} '{if($2 == marker) print}' $TMP_DIR/${IDSAMPLE}.${bfileloc}.map | wc -l| awk '{print $1}')
  if [[ ${nC} -eq 1 ]] ; then
       #head $TMP_DIR/${IDSAMPLE}.${bfileloc}.map
       awk -v marker=${SNP} '{if($2 == marker) print $2}' $TMP_DIR/${IDSAMPLE}.${bfileloc}.map > $TMP_DIR/${IDSAMPLE}.${bfileloc}.extract
       #cut -b1-200 $TMP_DIR/${IDSAMPLE}.${bfileloc}.ped
       #head $TMP_DIR/${IDSAMPLE}.${bfileloc}.map 
       $FRG_DIR/plink --ped $TMP_DIR/${IDSAMPLE}.${bfileloc}.ped --map $TMP_DIR/${IDSAMPLE}.${bfileloc}.map --allow-no-sex --missing-genotype '0' --missing-phenotype '9' --cow --extract $TMP_DIR/${IDSAMPLE}.${bfileloc}.extract --recode --out $TMP_DIR/${IDSAMPLE}.${bfileloc}.SHOWING > /dev/null
       awk -v s=${SNP} -v a=${bfileloc} '{print s,a,$7,$8}' $TMP_DIR/${IDSAMPLE}.${bfileloc}.SHOWING.ped
  fi
done
#schneiden des nachgefragten SNP aus der ISAG GenoEx-PSE map
echo " "
IsISAG=$(awk '{ sub("\r$", ""); print }' ${ISAGPARENTAGESBOLIST} | awk -v marker=${SNP} 'BEGIN{FS=";"}{if($1 == marker) print}' | wc -l | awk '{print $1}')
if [ ${IsISAG} -gt 0 ]; then
   echo "Attention: Marker is on ISAG GenoEx-PSE List ${ISAGPARENTAGESBOLIST}"
   awk '{ sub("\r$", ""); print }' ${ISAGPARENTAGESBOLIST} | awk -v marker=${SNP} 'BEGIN{FS=";"}{if($1 == marker) print}'
fi




echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
