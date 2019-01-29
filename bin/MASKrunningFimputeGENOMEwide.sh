#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

###############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit

if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL oder VMS "
    exit 1
else 
set -o nounset
    BTA=wholeGenome
    BREED=$(echo "$1")
    echo "running runFimpute Routine BTA${BTA} for breed ${BREED}:"

    cd $FIM_DIR

    cat $PAR_DIR/MASKFimpute_standard.ctr | sed "s/BTAX/BTA${BTA}/g" | sed "s/XXXXXXX/${BREED}/g" >  MASK${BREED}Fimpute_standard.ctr

    $FRG_DIR/FImpute_Linux MASK${BREED}Fimpute_standard.ctr -o

fi



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
