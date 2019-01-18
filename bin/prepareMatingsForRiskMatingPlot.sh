#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source $lokal/parfiles/steuerungsvariablen.ctr.sh
###############################################################

OS=$(uname -s)
if [ $OS = "Linux" ]; then
  getZahlenArray () {
    arr_=$(seq $1 $2)
  }
elif [ $OS = "Darwin" ]; then
  getZahlenArray () {
    arr_=$(jot - $1 $2)
  }
else
  echo "FEHLER: Unbekannters Betriebssystem ($OS) --> PROGRAMMABBRUCH"
  exit 1
fi


# check number of command line arguments
# function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options BSW or HOL"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts ":b:" FLAG; do
  case $FLAG in
    b) #set option "b"
      export breed=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${breed} != "BSW" ] && [ ${breed} != "HOL" ]; then 
      echo "breed -b not correct, must be BSW or HOL"
      exit 1
      fi
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done
#shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
### # check that breed is not empty
if [ -z "${breed}" ]; then
 usage 'Breed not specified, must be specified using option -b <string>'
 exit 1
fi
set -o errexit
set -o nounset

if [ ${breed} == "HOL" ] ; then
  DatPEDI=$DatPEDIshb
  pedigree=/qualstore03/data_zws/pedigree/work/rh/pedi_shb_shzv.dat
  shc=SHB
fi
if [ ${breed} == "BSW" ] ; then
  DatPEDI=$DatPEDIbvch
  pedigree=/qualstore03/data_zws/pedigree/work/bv/${DatPEDIbvch}_pedigree_rrtdm_BVJE.dat
  shc=BVCH
fi



#Original-Datei ZWS fbk lesen zaehle Anzahl Besamungen im letzten Jahr von jedem Stier
if [ ${breed} == "BSW" ]; then
chs=$(echo ${shc} | awk '{print tolower($1)}')
inputfolder=$ARC_DIR/repositoryFBK/${chs}/
namesOffiles=fbk
lastani=0
awk '{if(substr($0,75,2) != "  " && substr($0,41,14) != "              " && substr($0,134,8) == "        ") print substr($0,1,14),substr($0,33,8),substr($0,41,14),substr($0,75,2)}' ${inputfolder}/${namesOffiles}*.dat > $TMP_DIR/${breed}.lastInseminations.lst 
fi
if [ ${breed} == "HOL" ]; then
chs=$(echo ${shc} | awk '{print tolower($1)}')
inputfolder=$ARC_DIR/repositoryFBK/${chs}/
namesOffiles=fbk
lastani=0
awk '{if(substr($0,75,2) != "  " && substr($0,41,14) != "              " && substr($0,134,8) == "        ") print substr($0,1,14),substr($0,33,8),substr($0,41,14),substr($0,75,2)}' ${inputfolder}/${namesOffiles}*.dat > $TMP_DIR/${breed}.lastInseminations.shb
#daten vom Holsteinverband: keine automatisch generierte Trächtigkeiten !!!!
inputfolder=$ARC_DIR/repositoryFBK/shzv/
namesOffiles=FER
awk '{if(substr($0,74,2) != "  " && substr($0,41,14) != "              ") print substr($0,1,14),substr($0,33,8),substr($0,41,14),substr($0,74,2)}' ${inputfolder}/${namesOffiles}*.txt > $TMP_DIR/${breed}.lastInseminations.shzv
(cat $TMP_DIR/${breed}.lastInseminations.shzv;
cat $TMP_DIR/${breed}.lastInseminations.shb) |\
 sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 -k2,2nr -k3,3 > $TMP_DIR/${breed}.lastInseminations.lst
rm -f $TMP_DIR/${breed}.lastInseminations.shb $TMP_DIR/${breed}.lastInseminations.shzv
fi



#add sire of inseminated cow
awk 'BEGIN{FS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));pt[substr($0,58,14)]=substr($0,12,10);}} \
    else {sub("\015$","",$(NF));STAT="0";SD=pt[substr($0,1,14)]; \
    if   (SD != "") {print $1";"SD";"substr($2,1,4)";"$3";"$4}}}' ${pedigree} $TMP_DIR/${breed}.lastInseminations.lst  > $TMP_DIR/${breed}.lastInseminations.sire

awk 'BEGIN{FS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));pt[substr($0,1,10)]=substr($0,58,14);}} \
    else {sub("\015$","",$(NF));STAT="0";SD=pt[substr($0,16,10)]; \
    if   (SD != "") {print $1";"SD";"$3";"$4";"$5}}}' ${pedigree} $TMP_DIR/${breed}.lastInseminations.sire > $TMP_DIR/${breed}.lastInseminations.sireTVD
 
    
cat $TMP_DIR/${breed}.lastInseminations.sireTVD | tr ';' ' ' > $TMP_DIR/${breed}.lastInseminations.lst
rm -f $TMP_DIR/${breed}.lastInseminations.sireTVD
rm -f $TMP_DIR/${breed}.lastInseminations.sire


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
