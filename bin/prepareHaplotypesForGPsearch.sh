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
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b: FLAG; do
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

    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that breed is not empty
if [ -z "${breed}" ]; then
      usage 'BREED not specified, must be specified using option -b <string>'   
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


if ! test -s $FIM_DIR/${breed}.GPsearch.out/genotypes_imp.txt ;then
   echo "$FIM_DIR/${breed}.GPsearch.out/genotypes_imp.txt does not exist or has size zero"
   exit 1
fi



#to do file transposen damit logik behalten werden kann. Neu hier nur der Haplotypenbock Statt das ganze BTA
awk '{if(NR > 1) print $3}' $FIM_DIR/${breed}.GPsearch.out/genotypes_imp.txt | sed 's/./& /g' > $TMP_DIR/${breed}.GPsearch.Fgt.tmp
#erster transpose macht umstrukturerung von rows in colums und von 1 Zeile pro Tier zu 2 colums pro tier nur Genotypen, sed -f codiert von Fimpute Diplotypencalling in Allelcalling um
cp ${PAR_DIR}/Fimpute.standard.output.allelecoding.lst.sed ${TMP_DIR}/Fimpute.standard.output.allelecoding.lst.sed.GPsearch
$BIN_DIR/awk_transpose.job $TMP_DIR/${breed}.GPsearch.Fgt.tmp | sed -f ${TMP_DIR}/Fimpute.standard.output.allelecoding.lst.sed.GPsearch > $TMP_DIR/${breed}.GPsearch.Fgt.transposed
#zweiter transpose macht struktur von spaltenweise in zeilenweise zurück, jetzt aber 2 Zeilen pro tier im output
awk '{if(NR > 1) print $1,$1}' $FIM_DIR/${breed}.GPsearch.out/genotypes_imp.txt | tr ' ' '\n' > $TMP_DIR/${breed}.GPsearch.Fgt.animals
$BIN_DIR/awk_transpose.job $TMP_DIR/${breed}.GPsearch.Fgt.transposed  > $TMP_DIR/${breed}.GPsearch.Fgt.haplotypesInRows
#*.animals und *.haplotyieInRows sind gleich sortiert
#paste -d' ' $TMP_DIR/${breed}.GPsearch.Fgt.animals $TMP_DIR/${breed}.GPsearch.Fgt.haplos.tmp > $TMP_DIR/${breed}.GPsearch.Fgt.haplotypesInRows
sed -i 's/B/2/g' $TMP_DIR/${breed}.GPsearch.Fgt.haplotypesInRows
sed -i 's/A/1/g' $TMP_DIR/${breed}.GPsearch.Fgt.haplotypesInRows
sed -i 's/ //g'  $TMP_DIR/${breed}.GPsearch.Fgt.haplotypesInRows

cat $TMP_DIR/${breed}.GPsearch.Fgt.haplotypesInRows | sed 's/B/2/g' | sed 's/A/1/g' | sed 's/ /_/g' | sed 's/_/ /1' | sed 's/_//g' > $TMP_DIR/${breed}.GPsearch.FgtN.haplotypesInRows

if false; then
#aufteilen in die 29 autosomalen BTAs
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29; do
startbyte=$(awk -v j=${i} '{if($2 == j) print NR-1}' $FIM_DIR/${breed}.GPsearch_FImpute.snpinfo | head -1)
endebyte=$(awk -v j=${i} '{if($2 == j) print NR-1}' $FIM_DIR/${breed}.GPsearch_FImpute.snpinfo | tail -1)
deltabyte=$(echo $endebyte $startbyte | awk '{print $1-$2}')
echo $i $startbyte $endebyte $deltabyte
awk -v s=${startbyte} -v e=${deltabyte} '{print substr($1,s,e)}' $TMP_DIR/${breed}.GPsearch.Fgt.haplotypesInRows > $TMP_DIR/${breed}.GPsearch.Fgt.haplotypesInRows.${i}
done
fi

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT} 

