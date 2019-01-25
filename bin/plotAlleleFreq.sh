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
      export breed=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${breed} == "BSW" ] || [ ${breed} == "HOL" ] || [ ${breed} == "VMS" ]; then
          echo ${breed} > /dev/null
          if [ ${breed} == "BSW" ]; then
             natfolder=sbzv
          fi
          if [ ${breed} == "HOL" ]; then
             natfolder=swissherdbook
          fi
          if [ ${breed} == "vms" ]; then
             natfolder=mutterkuh
          fi
      else
          usage "Breed not correct, must be specified: bsw / hol / vms using option -b <string>"
          exit 1
      fi
      ;;
    d) # set option "s"
      export defectcode=$(echo $OPTARG)
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that breed is not empty
if [ -z "${breed}" ]; then
      usage 'BREED not specified, must be specified using option -b <string>'   
fi
### # check that setofanomals is not empty
if [ -z "${defectcode}" ]; then
    usage 'Parameter for the polymophism must be specified using option -z <string>'      
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

##########################################################################################
getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colSCT=$colNr_
getColmnNr PredictionAlgorhithm ${REFTAB_SiTeAr} ; colCAI=$colNr_
algorithm=$(awk -v snps=${defectcode} -v a=${colSCT} -v b=${colCAI} 'BEGIN{FS=";"}{if($a == snps) print $b}' ${REFTAB_SiTeAr})






Rscript $BIN_DIR/ggplotHaplotypeAllelFrq.R ${breed} $RES_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm} $PDF_DIR/LinePlot_alleleFrequenz_${breed}.${defectcode} $RES_DIR/Allelfrequenz_Ballele_${breed}.${defectcode} ${defectcode} 



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
