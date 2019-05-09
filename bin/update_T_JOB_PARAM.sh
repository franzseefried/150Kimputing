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

if [ -z $1 ]; then
    echo "brauche den Code fuer das Parametefile"
    exit 1
fi



if [ ${dbsystem} != "rapid" ]; then
   DEUTZ_DIR=/qualstororatest01/argus_${dbsystem}/
fi

if ! test -s ${DEUTZ_DIR}/sbzv/dsch/in/${1} ; then
echo "Parameterfile existiert nicht"
exit 1
fi


#HOST=rapid.braunvieh.ch
HOST=$(echo ${dbsystem}.braunvieh.ch)
SERVICE=AR01.braunvieh.ch
USERNAME=gestho
PASSWORD=gestho
MANDANT=SBZV



# Prepare and run sql-program to purge the location data
#=======================================================
if ! test -s $BIN_DIR/update_T_JOB_PARAM.sql; then
    >&2 echo "Error: $BIN_DIR/update_T_JOB_PARAM.sql does not exist or is empty"
    exit 1
fi
cd ${DEUTZ_DIR}/sbzv/dsch/in

LCLJOBID=$(cat ${DEUTZ_DIR}/sbzv/dsch/out/jobid.txt )
cat $BIN_DIR/update_T_JOB_PARAM.sql | sed "s/MANDANTTNADNAM/${MANDANT}/g" | sed "s/XXXXXXXXXX/${1}/g" | sed "s/YYYYYYYYYY/${LCLJOBID}/g" > update_T_JOB_PARAM.doit.sql
    
#cat update_T_JOB_PARAM.doit.sql
echo ${USERNAME}/${PASSWORD}@//${HOST}:1521/${SERVICE}
sql ${USERNAME}/${PASSWORD}@//${HOST}:1521/${SERVICE} @update_T_JOB_PARAM.doit.sql
sleep 10



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

