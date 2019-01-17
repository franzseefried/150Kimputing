#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " " 

##############################################################
lokal=$(pwd | awk '{print $1}')
source $lokal/parfiles/steuerungsvariablen.ctr.sh
##############################################################
set -o errexit
set -o nounset

lauf=${run}

#loeschen LIMS einzelgenfiles
rm -f ${LIMS_DIR}/*.csv

echo $BCP_DIR/$lauf
mkdir -p $BCP_DIR/$lauf
mkdir -p $BCP_DIR/$lauf/log
mkdir -p $BCP_DIR/$lauf/parfiles


echo "copy current files to $BCP_DIR/$lauf/"
echo " "
cp $PAR_DIR/* $BCP_DIR/$lauf/parfiles/.
cd $BCP_DIR/$lauf/parfiles
gzip *
cd ${MAIN_DIR}

cp $LOG_DIR/* $BCP_DIR/$lauf/log/.
cd $BCP_DIR/$lauf/log
gzip *
cd ${MAIN_DIR}
rm -f ${HIS_DIR}/*${old2run}*TVD


echo " "
echo "delete files from old4run ${old4run} run"
for i in $(ls -trl ${HIS_DIR}/*${old4run}* |  awk '{print $9}' | grep -v SumUpLOG | grep -v tierlis | grep -v ${old3run}); do 
rm -f ${i}; 
done

echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
