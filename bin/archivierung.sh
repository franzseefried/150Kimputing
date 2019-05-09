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



#loeschen LIMS einzelgenfiles
rm -f ${LIMS_DIR}/*.csv

echo $BCP_DIR/${run}
mkdir -p $BCP_DIR/${run}
mkdir -p $BCP_DIR/${run}/log
mkdir -p $BCP_DIR/${run}/parfiles
mkdir -p $BCP_DIR/${run}/prog
mkdir -p $BCP_DIR/${run}/bin
mkdir -p $BCP_DIR/${run}/work
echo "copy current files to $BCP_DIR/${run}/"
echo " "
cp $PAR_DIR/* $BCP_DIR/${run}/parfiles/.
cd $BCP_DIR/${run}/parfiles
gzip *
cd ${MAIN_DIR}

cp $LOG_DIR/* $BCP_DIR/${run}/log/.
cd $BCP_DIR/${run}/log
gzip *
cd ${MAIN_DIR}

cp $PROG_DIR/* $BCP_DIR/${run}/prog/.
cd $BCP_DIR/${run}/prog
gzip *
cd ${MAIN_DIR}

cp $BIN_DIR/* $BCP_DIR/${run}/bin/.
cd $BCP_DIR/${run}/bin
gzip *
cd ${MAIN_DIR}


cp $WORK_DIR/ped_umcodierung.txt.* $BCP_DIR/${run}/work/.
cp $WORK_DIR/*Typisierungsstatus${run}.txt $BCP_DIR/${run}/work/.
cp $WORK_DIR/animal.overall.info $BCP_DIR/${run}/work/.
cd $BCP_DIR/${run}/work/
gzip *
cd ${MAIN_DIR}


echo "delete files from old4run ${old4run} run"
rm -f ${HIS_DIR}/*${old4run}*



echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
