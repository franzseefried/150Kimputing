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
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'ALL'"
    exit 1
else
set -o nounset
	razza=$(echo ${1})
	
	
    n1=$(grep "progeny-parent mismatches" ${FIM_DIR}/${razza}BTAwholeGenome.out/report.txt  | awk 'BEGIN{FS=":"}{if(NR == 1) print gsub($2," ","")}' )


    if [ ${n1} -eq 0 ]; then
	   Fcheck=0
    else
       Fcheck=1
    fi 
  

    if [ ${Fcheck} -eq 0 ] ; then
echo "To: ${MAILACCOUNT}
From: ${MAILACCOUNT}
Subject: ...FImpute check for ${1}...

FImpute Logfile sieht gut aus.... " | ssmtp ${MAILACCOUNT}

else
echo "To: ${MAILACCOUNT}
From: ${MAILACCOUNT}
Subject: ...FImpute check for ${1}...

oooops FImpute hat missmatches bei der parentage.... " | ssmtp ${MAILACCOUNT}

exit 1

fi

fi

echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
