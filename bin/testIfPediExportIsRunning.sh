#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

#######################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
#######################################################
set -o errexit
set -o nounset



if [ ${dbsystem} != "rapid" ]; then
   DEUTZ_DIR=/qualstororatest01/argus_${dbsystem}
fi




#HOST=rapid.braunvieh.ch
HOST=$(echo ${dbsystem}.braunvieh.ch)
SERVICE=AR01.braunvieh.ch
USERNAME=gestho
PASSWORD=gestho
MANDANT=SBZV



# Prepare and run sql-program to purge the location data
#=======================================================
if ! test -s $BIN_DIR/testIfPediExportIsRunning.sql; then
    >&2 echo "Error: $BIN_DIR/testIfPediExportIsRunning.sql does not exist or is empty"
    exit 1
fi
cd ${DEUTZ_DIR}/sbzv/dsch/in

cat $BIN_DIR/testIfPediExportIsRunning.sql | sed "s/MANDANTTNADNAM/${MANDANT}/g" > testIfPediExportIsRunning.doit.sql
    
#cat testIfPediExportIsRunning.doit.sql
echo ${USERNAME}/${PASSWORD}@//${HOST}:1521/${SERVICE}
sql ${USERNAME}/${PASSWORD}@//${HOST}:1521/${SERVICE} @testIfPediExportIsRunning.doit.sql

if ! test -s ${DEUTZ_DIR}/sbzv/dsch/out/jobstatus.txt; then
echo "OUTFILE ${DEUTZ_DIR}/sbzv/dsch/out/jobstatus.txt is empty but needed for follwoing steps"
exit 1
fi
nl=$(wc -l ${DEUTZ_DIR}/sbzv/dsch/out/jobstatus.txt | awk '{print $1}' )
if [ ${nl} != 1 ]; then
echo "OUTFILE ${DEUTZ_DIR}/sbzv/dsch/out/jobstatus.txt is suspicious in terms of content"
exit 1
fi
cp ${DEUTZ_DIR}/sbzv/dsch/out/jobstatus.txt $TMP_DIR/.
sleep 10


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

