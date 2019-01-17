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
   DEUTZ_DIR=/qualstororatest01/argus_${dbsystem}/
fi




#HOST=rapid.braunvieh.ch
HOST=$(echo ${dbsystem}.braunvieh.ch)
SERVICE=AR01.braunvieh.ch
USERNAME=gestho
PASSWORD=gestho
MANDANT=SBZV



# Prepare and run sql-program to purge the location data
#=======================================================
if ! test -s $BIN_DIR/getJOBIDfromPediExport.sql; then
    >&2 echo "Error: $BIN_DIR/getJOBIDfromPediExport.sql does not exist or is empty"
    exit 1
fi
cd ${DEUTZ_DIR}/sbzv/dsch/in
rm -f ${DEUTZ_DIR}/sbzv/dsch/out/jobid.txt 
cat $BIN_DIR/getJOBIDfromPediExport.sql | sed "s/MANDANTTNADNAM/${MANDANT}/g" > getJOBIDfromPediExport.doit.sql
    
#cat getJOBIDfromPediExport.doit.sql
echo ${USERNAME}/${PASSWORD}@//${HOST}:1521/${SERVICE}
sql ${USERNAME}/${PASSWORD}@//${HOST}:1521/${SERVICE} @getJOBIDfromPediExport.doit.sql

if ! test -s ${DEUTZ_DIR}/sbzv/dsch/out/jobid.txt; then
echo "OUTFILE ${DEUTZ_DIR}/sbzv/dsch/out/jobid.txt is empty but needed for follwoing steps"
exit 1
fi
nl=$(awk '{ sub("\r$", ""); print }' ${DEUTZ_DIR}/sbzv/dsch/out/jobid.txt | wc -l | awk '{print $1}' )
if [ ${nl} != 1 ]; then
echo "OUTFILE ${DEUTZ_DIR}/sbzv/dsch/out/jobid.txt is suspicious in terms of content"
exit 1
fi

sleep 10


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

