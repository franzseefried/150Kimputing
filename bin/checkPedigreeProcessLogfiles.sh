#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "



##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################



if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'ALL'"
    exit 1
else

	razza=$(echo ${1})
	
	
    n1=$(grep -i "PROGRAMMABBRUCH" $LOG_DIR/1masterskriptMixIncomingWiExistingSNPndPrepPedi_${razza}.log | wc -l | awk '{print $1}' )
    #n2=$(grep -i "error" $TMP_DIR/${razza}*.log | wc -l | awk '{print $1}')
    #n3=$(grep -i "fail" $WORK_DIR/${razza}*.log | grep -v "after larger attempt" | wc -l | awk '{print $1}')
    #n4=$(grep -i "fail" $TMP_DIR/${razza}*.log | grep -v "after larger attempt" | wc -l | awk '{print $1}')
    #n5=$(grep -i "fatal" $WORK_DIR/${razza}*.log | wc -l | awk '{print $1}')
    #n6=$(grep -i "fatal" $TMP_DIR/${razza}*.log | wc -l | awk '{print $1}')

    #if [ ${n1} == ${n2} ] && [ ${n1} == ${n3} ] && [ ${n1} == ${n4} ] && [ ${n1} == ${n5} ] && [ ${n1} == ${n6} ] && [ ${n1} -eq 0 ]; then
    if [ ${n1} -eq 0 ]; then
	   pedicheck=0
    else
       pedicheck=1

    echo "look here where the problem was:......."
    grep -n -i "PROGRAMMABBRUCH" $LOG_DIR/1masterskriptMixIncomingWiExistingSNPndPrepPedi_${razza}.log | wc -l | awk '{print $1}'
    #grep -i "error" $TMP_DIR/${razza}*.log | wc -l | awk '{print $1}'
    #grep -i "fail" $WORK_DIR/${razza}*.log | grep -v "after larger attempt" | wc -l | awk '{print $1}'
    #grep -i "fail" $TMP_DIR/${razza}*.log | grep -v "after larger attempt" | wc -l | awk '{print $1}'
    #grep -i "fatal" $WORK_DIR/${razza}*.log | wc -l | awk '{print $1}'
    #grep -i "fatal" $TMP_DIR/${razza}*.log | wc -l | awk '{print $1}'
    echo " "

    fi 
  

    if [ ${pedicheck} -eq 0 ] ; then
echo "To: ${MAILACCOUNT}
From: ${MAILACCOUNT}
Subject: ...PedigreeProcessing check fuer ${1}...

Logfiles aus PedigreeProcessing sehen gut aus fuer ${1}.... .... " | ssmtp ${MAILACCOUNT}

else
echo "To: ${MAILACCOUNT}
From: ${MAILACCOUNT}
Subject: ...PedigreeProcessing check for ${1}...

OOOOPS PedigreeProcessing hat PROBLEM: check $LOG_DIR/1masterskriptMixIncomingWiExistingSNPndPrepPedi_${razza}.log.... .... " | ssmtp ${MAILACCOUNT}
exit 1

fi

fi

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
