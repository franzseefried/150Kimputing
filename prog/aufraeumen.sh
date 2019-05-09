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
set -o nounset


${BIN_DIR}/archivierung.sh

echo "loesche files im $TMP_DIR"
rm -rf $TMP_DIR
mkdir -p $TMP_DIR
echo "loesche files im $GCA_DIR"
rm -rf $GCA_DIR
mkdir -p $GCA_DIR
echo "loesche files im $WORK_DIR"
rm -rf $WORK_DIR
mkdir -p $WORK_DIR
echo "loesche files im $FIM_DIR"
rm -rf $FIM_DIR/*
echo "loesche files im $SMS_DIR"
rm -rf $SMS_DIR/*
echo "loesche files im $LOG_DIR"
rm -f $LOG_DIR/*
if [ -d "${LAB_DIR}" ]; then
   echo Loesche files im $LAB_DIR
   ls -trl $LAB_DIR/
   rm -f $LAB_DIR/*
   ls -trl $LAB_DIR/
fi

for dd in ${secondIMPUTATIONDIR}; do 
  echo "pruge now ${dd} direcctory"
  cd ${dd}
  ${secondIMPUTATIONDIR}/prog/aufraeumen.sh
  cd ${lokal}
  echo " ";
done



RIGHT_NOW=$(date )
echo "endeeeeeeeeeeee"
echo $RIGHT_NOW Ende ${SCRIPT}
