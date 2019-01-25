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


iheute=$(date '+%Y%m%d')
getColmnNr PredictionAlgorhithm ${REFTAB_SiTeAr} ; colPA=$colNr_
getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colCode=$colNr_
getColmnNr MarkerID ${REFTAB_SiTeAr} ; colMARKER=$colNr_
getColmnNr Kennung ${REFTAB_SiTeAr} ; colKenn=$colNr_
getColmnNr Testtyp ${REFTAB_SiTeAr} ; colType=$colNr_
getColmnNr IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBREED=$colNr_
#echo "${colCode} ; ${defectcode} ; ${colIMPBREED} ; ${breed}"
algorithm=$(awk -v a=${colCode} -v b=${defectcode} -v c=${colIMPBREED} -v d=${breed} -v f=${colPA} '{FS=";"} {if ($a == b && $c ~ d)print $f}' ${REFTAB_SiTeAr})


#define inputfile
infilename=$(ls $RES_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm}) 


#add Haplotype status of dams sire and inseminated bull
awk 'BEGIN{FS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));pt[$1]=$2;}} \
    else {sub("\015$","",$(NF));SD=pt[$2];SS=pt[$4]; \
    if   (SD != "" && SS != "" && SD > 0 && SS > 0) {print $1,$2,$3,$4}}}' ${infilename} $TMP_DIR/${breed}.lastInseminations.lst > $TMP_DIR/${breed}.lastInseminations.lst.${defectcode}

if ! test -s $TMP_DIR/${breed}.lastInseminations.lst.${defectcode}; then
echo "Habe keine laufenden Risikopaarungen fuer ${breed} und ${defectcode}"; 
else
Rscript $BIN_DIR/ggplotNoOfRiskmatings.R ${breed} ${defectcode} $TMP_DIR/${breed}.lastInseminations.lst.${defectcode} $PDF_DIR/${breed}_${defectcode}_NoOfRiskmatingsOverTime.pdf 
rm -f $TMP_DIR/${breed}.lastInseminations.lst.${defectcode}
fi

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
