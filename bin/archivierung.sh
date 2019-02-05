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
mkdir -p $BCP_DIR/$lauf/prog
mkdir -p $BCP_DIR/$lauf/bin
mkdir -p $BCP_DIR/$lauf/work
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

cp $PROG_DIR/* $BCP_DIR/$lauf/prog/.
cd $BCP_DIR/$lauf/prog
gzip *
cd ${MAIN_DIR}

cp $BIN_DIR/* $BCP_DIR/$lauf/bin/.
cd $BCP_DIR/$lauf/bin
gzip *
cd ${MAIN_DIR}


cp $WORK_DIR/ped_umcodierung.txt.* $BCP_DIR/$lauf/work/.
cp $WORK_DIR/*Typisierungsstatus${run}.txt $BCP_DIR/$lauf/work/.
cp $WORK_DIR/animal.overall.info $BCP_DIR/$lauf/work/.
cd $BCP_DIR/$lauf/work/
gzip *
cd ${MAIN_DIR}


rm -f ${HIS_DIR}/*${old2run}*TVD


echo "delete files from old4run ${old4run} run"
rm -f ${HIS_DIR}/*${old4run}*



echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
