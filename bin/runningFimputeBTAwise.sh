#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}  
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################



if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
elif [ -z $2 ]; then
    echo "brauche den numerischen Code fuer das Chromosom: z.B. '1' "
    exit 1
elif [ -z $3 ]; then
    echo "brauche den Code fur den SNP z.B. SDMNSP '1' "
    exit 1
else 
    BTA=$(echo "$2")
    BREED=$(echo "$1")
    snp=$(echo "$3")
    echo "running runFimpute Routine BTA${BTA} for breed ${BREED}:"



    cd $FIM_DIR

    cat $PAR_DIR/Fimpute_BTAsingleGene.ctr | sed "s/BTAX/BTA${BTA}/g" | sed "s/ZZZZZZZZZZ/${snp}/g" | sed "s/XXXXXXX/${BREED}/g" >  ${breed}Fimpute_BTA${BTA}${snp}.ctr

    $FRG_DIR/FImpute_Linux ${breed}Fimpute_BTA${BTA}${snp}.ctr -o

   cd $lokal
fi



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
