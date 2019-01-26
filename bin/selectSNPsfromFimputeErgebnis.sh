#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT} 
echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit

if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
fi
if [ -z $2 ]; then
    echo "brauche den Code fuer die Startrow"
    exit 1
fi
if [ -z $3 ]; then
    echo "brauche den Code fuer die Endrow "
    exit 1
fi
if [ -z $4 ]; then
    echo "brauche den Code fuer die Loopnummer "
    exit 1
fi
set -o nounset


awk -v s=${2} -v p=${3} '{if(NR >= s && NR <= p) print $3}'     $TMP_DIR/${1}.fmptrgb.txt > $TMP_DIR/${1}.fmptrgb.txt.${4}
awk -v s=${2} -v p=${3} '{if(NR >= s && NR <= p) print $1,"2"}' $TMP_DIR/${1}.fmptrgb.txt > $TMP_DIR/${1}.fergeb.animals.txt.${4}
rm -f $TMP_DIR/${1}.fmptrgb.txt.${4}.out $TMP_DIR/${1}LD.fimpute.ergebnis.${run}.${4}
Rscript $BIN_DIR/selectSNPsfromFimputeErgebnis.R $TMP_DIR/${1}.selectedColsforGTfile $TMP_DIR/${1}.fmptrgb.txt.${4}
sed -i 's/ //g' $TMP_DIR/${1}.fmptrgb.txt.${4}.out
sed -i "s/[5-9]/5/g" $TMP_DIR/${1}.fmptrgb.txt.${4}.out
paste -d' ' $TMP_DIR/${1}.fergeb.animals.txt.${4} $TMP_DIR/${1}.fmptrgb.txt.${4}.out > $TMP_DIR/${1}LD.fimpute.ergebnis.${run}.${4}



echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
