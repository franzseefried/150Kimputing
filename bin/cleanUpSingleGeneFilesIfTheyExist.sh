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
START_DIR=$(pwd)


if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
elif [ ${1} == "BSW" ] || [ ${1} == "HOL" ]  || [ ${1} == "VMS" ]; then

if [ ${1} == "BSW" ]; then
	zofol=$(echo "bvch")
fi
if [ ${1} == "HOL" ]; then
	zofol=$(echo "shb")
fi
if [ ${1} == "VMS" ]; then
        zofol=$(echo "vms")
fi
else 
  echo "unbekannter Systemcode BSW VMS oder HOL erlaubt"
  exit 1
fi


if [ -z $2 ]; then
   echo "brauche den Code für die Chipdichte HD oder LD"
   exit 1
elif [ $2 == "LD" ] || [ $2 == "HD" ]; then
   echo $2 > /dev/null
   dichte=${2}
else
   echo "Der Code fuer die Chipdichte muss LD oder HD sein, ist aber ${2}"
   exit 1
fi

set -o nounset

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

#get Info about SNP from Reftab
getColmnNrSemicl ExtractGenotypesFromChipData ${REFTAB_SiTeAr} ; colEXG=$colNr_
getColmnNrSemicl CodeResultfile ${REFTAB_SiTeAr} ; colCSGI=$colNr_
getColmnNrSemicl BezeichnungFinalReport ${REFTAB_SiTeAr} ; colGSB=$colNr_
getColmnNrSemicl IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBRD=$colNr_
#echo $colCSGI $colGSB

rm -f $TMP_DIR/*.singleGeneImputationPreparation.tmp

breed=${1}

#idUmcodierung idanimal zu PediID
awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | awk 'BEGIN{FS=";"}{print $1";"$2}' | sed 's/ //g' | tr ';' ' '  > $TMP_DIR/umcd.lst1

#scuche welche Tests aus dem Archiv geholt werden sollen
TestsToBeExtracted=$(awk -v a=${colEXG} -v b=${colGSB} -v c=${colIMPBRD} -v d=${breed} 'BEGIN{FS=";"}{if($a == "Y" && $c ~ d) print $b}' ${REFTAB_SiTeAr} )
#echo $TestsToBeExtracted




#loeschen falls file schon existiert
for sssnp in ${TestsToBeExtracted}; do
if test -s $WRK_DIR/${breed}.${sssnp}.lst; then
    echo "first I delete $WRK_DIR/${breed}.${sssnp}.lst"
    rm -f $WRK_DIR/${breed}.${sssnp}.lst
fi
done



cd $lokal

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
