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
if [ -z $5 ]; then
    echo "brauche den Code fuer das Vglfile "
    exit 1
fi

set -o nounset
breed=${1}
vglfile=${5}

awk -v s=${2} -v p=${3} '{if(NR >= s && NR <= p) print $0}'     $CMP_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun} > $CMP_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}.${4}
#loeschen des OUTfiles
rm -f $CMP_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}.${4}.out
Rscript $BIN_DIR/readAndCompareFimputeResult_lineBYline.R ${PAR_DIR}/steuerungsvariablen.ctr.sh $CMP_DIR/${breed}.IMPresult.${vglfile}.compare.RUN${run}.vs.RUN${oldrun}.${4}

echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
