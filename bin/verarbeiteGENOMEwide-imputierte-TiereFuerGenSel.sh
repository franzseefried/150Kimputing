#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit

### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options BSW or HOL"
  echo "  where <string> valid options are BSW or HOL"
  echo "Usage: $SCRIPT -c <string>"
  echo "  where <string> specifies the Parameter for Chipstatus for animals to be taken"
  echo "  where <string> valid options are 0, 1 or 2"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b:c: FLAG; do
  case $FLAG in
    b) # set option "b"
      breed=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${breed} == "BSW" ] || [ ${breed} == "HOL" ]  || [ ${breed} == "VMS" ]; then
          echo ${breed} > /dev/null
      else
          usage 'Breed not correct, must be specified: BSW or HOL or VMS using option -b <string>'
      fi
      ;;
    c) # set option "a"
      chip=$(echo $OPTARG )
      if [ ${chip} -eq  0 ] || [ ${chip} -eq 1 ] || [ ${chip} -eq 2 ]; then
          echo ${chip} > /dev/null
      else
          usage 'Parameter for Chip not correct, must be specified: 0 or 1 or 2 using option -c <string>'
      fi
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
### # check that breed is not empty
if [ -z "${breed}" ]; then
      usage 'BREED not specified, must be specified using option -b <string>'   
fi
### # check that parent is not empty
if [ -z "${chip}" ]; then
    usage 'Parameter for CHIP must be specified using option -c <string>'      
fi

set -o nounset

#mapfiles herrichten ACHTUNG nehme nur autosomale SNPs im ersten schritt
cat $FIM_DIR/${breed}BTAwholeGenome_FImpute.snpinfo | sed -n '2,$p' | awk '{printf "%+35s%+10s%+19s%+20s\n", $1,$2,$3,$4 }' > $GSE_DIR/${breed}LD50Kmap_fimpute.${run}.catalog
  
awk '{print $1,$4}' $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/ids${breed}idITB16.txt
$BIN_DIR/awk_umcodeVonEINSaufZWEImitLeerschlag $TMP_DIR/ids${breed}idITB16.txt $FIM_DIR/${breed}BTAwholeGenome.out/genotypes_imp.txt > $GSE_DIR/${breed}.fimpute.animals
rm -f $TMP_DIR/ids${breed}idITB16.txt
#Genotypenfile fuer alle Tiere mit fimpute ergebnis aufbauen
#    header aus dem mapfile holen snpfile unbekannte genotype calls heterozygot setzen
awk '{print $3 }' $FIM_DIR/${breed}BTAwholeGenome.out/genotypes_imp.txt | sed -n '2,$p' | awk '{gsub(".", "& ");print}' | sed 's/^/ /g' | sed "s/[5-9]/1/g" | sed 's/ 0/ X/g' | sed 's/ 2/ Y/g'  | sed 's/ 1/ 0/g' | sed 's/ X/ -10/g' | sed 's/ Y/ 10/g'  > $GSE_DIR/${breed}.fimpute.gts
(cut -d' ' -f4 $FIM_DIR/${breed}BTAwholeGenome_FImpute.snpinfo  | sed 's/Chip1/AnimalID /g' | tr '\n' ' ' | sed 's/$/\n/g' | sed 's/ n//g' | sed "s/ \{1,\}/ /g";
	paste -d' ' $GSE_DIR/${breed}.fimpute.animals $GSE_DIR/${breed}.fimpute.gts | sed 's/  / /g' | awk -v codeGeno=${chip} '{if($2 >= codeGeno)print $0}' | sed "s/ [0-9]//1")  > $GSE_DIR/${breed}LD50KIMP.${run}.dat
rm -f $GSE_DIR/${breed}.fimpute.gts
rm -f $TMP_DIR/${breed}.LD50Kfimpute.gts

n=$(wc -l $GSE_DIR/${breed}LD50KIMP.${run}.dat | awk '{print $1}')
echo "Genotypefile was generated: $GSE_DIR/${breed}LD50KIMP.${run}.dat und hat ${n} records"
nn=$(wc -l $FIM_DIR/${breed}BTAwholeGenome.out/genotypes_imp.txt | awk '{print $1}')
echo "Ausgangsfile $FIM_DIR/${breed}/${run}/${breed}BTAwholeGenome_FImpute.snpinfo und hatte ${nn} records"


#Markermap:
cat $FIM_DIR/${breed}BTAwholeGenome_FImpute.snpinfo | sed -n '2,$p' | awk '{printf "%+35s%+10s%+19s%+20s\n", $1,$2,$3,$4 }' > $GSE_DIR/${breed}LD50Kmap_fimpute.${run}.catalog
 

echo " "
RIGHT_NOW=$(date )
echo $RIGHT_NOW ENDE ${SCRIPT}

