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
	
	
    n1=$(grep -i "error" $WORK_DIR/${razza}*.log | wc -l | awk '{print $1}' )
    n2=$(grep -i "error" $TMP_DIR/${razza}*.log | wc -l | awk '{print $1}')
    n3=$(grep -i "fail" $WORK_DIR/${razza}*.log | grep -v "after larger attempt" | wc -l | awk '{print $1}')
    n4=$(grep -i "fail" $TMP_DIR/${razza}*.log | grep -v "after larger attempt" | wc -l | awk '{print $1}')
    n5=$(grep -i "fatal" $WORK_DIR/${razza}*.log | wc -l | awk '{print $1}')
    n6=$(grep -i "fatal" $TMP_DIR/${razza}*.log | wc -l | awk '{print $1}')


    if [ ${n1} == ${n2} ] && [ ${n1} == ${n3} ] && [ ${n1} == ${n4} ] && [ ${n1} == ${n5} ] && [ ${n1} == ${n6} ] && [ ${n1} -eq 0 ]; then
	   plinkcheck=0
    else
       plinkcheck=1

    echo "look here where the problem was:......."
    grep -i "error" $WORK_DIR/${razza}*.log | wc -l | awk '{print "error WORK_DIR",$1}' 
    grep -i "error" $TMP_DIR/${razza}*.log | wc -l | awk '{print "error TMP_DIR",$1}'
    grep -i "fail" $WORK_DIR/${razza}*.log | grep -v "after larger attempt" | wc -l | awk '{print "fail WORK_DIR",$1}'
    grep -i "fail" $TMP_DIR/${razza}*.log | grep -v "after larger attempt" | wc -l | awk '{print "fail TMP_DIR",$1}'
    grep -i "fatal" $WORK_DIR/${razza}*.log | wc -l | awk '{print "fatal WORK_DIR",$1}'
    grep -i "fatal" $TMP_DIR/${razza}*.log | wc -l | awk '{print "fatal TMP_DIR",$1}'
    echo " "

    fi 
  

    if [ ${plinkcheck} -eq 0 ] ; then
echo "To: ${MAILACCOUNT}
From: ${MAILACCOUNT}
Subject: ...PLINK check for ${1}...

PLINK Logfiles sehen gut aus for PLINKcheck out of ${MAIN_DIR} for ${1}.... .... " | ssmtp ${MAILACCOUNT}

else
echo "To: ${MAILACCOUNT}
From: ${MAILACCOUNT}
Subject: ...PLINK check for ${1}...

oooops PLINK hat PROBLEM: check PLINKcheck out of ${MAIN_DIR} for ${1}.... .... " | ssmtp ${MAILACCOUNT}


fi

fi

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
