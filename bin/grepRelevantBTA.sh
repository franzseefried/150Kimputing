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
   echo "brauche den Code für die Strategie SINGLEGENE SVM HAPLOTYPE STANDARD"
   exit 1
elif [ $2 == "SINGLEGENE" ] || [ $2 == "SVM" ] || [ $2 == "HAPLOTYPE" ] || [ $2 == "STANDARD" ]; then
   echo $2 > /dev/null
   strat=${2}
else
   echo "Der Code fuer die Strategie muss SINGLEGENE SVM HAPLOTYPE STANDARD sein, ist aber ${2}"
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
getColmnNrSemicl BTA ${REFTAB_SiTeAr} ; colGSB=$colNr_
getColmnNrSemicl PredictionAlgorhithm ${REFTAB_SiTeAr} ; colABAASGI=$colNr_
getColmnNrSemicl IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBRD=$colNr_
#echo $colCSGI $colGSB


breed=${1}


#suche welche Tests aus dem Archiv geholt werden sollen
checkB=$(awk -v a=${colABAASGI} -v b=${colGSB} -v c=${colIMPBRD} -v d=${breed} -v e=${strat} 'BEGIN{FS=";"}{if($a == e && $c ~ d) print $1}' ${REFTAB_SiTeAr} | wc -l |awk '{print $1}')
checkC=$(awk -v a=${colABAASGI} -v b=${colGSB} -v c=${colIMPBRD} -v d=${breed} -v e=${strat} 'BEGIN{FS=";"}{if($a == e && $c ~ d) print $b}' ${REFTAB_SiTeAr} |grep -v [a-z] | grep -v [A-Z] | grep [0-9] | wc -l|awk '{print $1}')

if [ ${checkB} != ${checkC} ]; then
echo "OOOPS: There are tests nominated for ${strat} which have suspicious chromomes.. check"
echo " "
exit 1
fi

#write file
BTAsToBeExtracted=$(awk -v a=${colABAASGI} -v b=${colGSB} -v c=${colIMPBRD} -v d=${breed} -v e=${strat} 'BEGIN{FS=";"}{if($a == e && $c ~ d) print $b}' ${REFTAB_SiTeAr} )
echo $BTAsToBeExtracted | tr ' ' '\n' | sort -u | tr '\n' ' ' > $TMP_DIR/${breed}.relevantBTAs.forSingleGeneImputation.txt

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
