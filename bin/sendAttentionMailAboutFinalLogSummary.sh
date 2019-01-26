#!/bin/bash 
SCRIPT=`basename ${BASH_SOURCE[0]}`
RIGHT_NOW=$(date)
echo $RIGHT_NOW Start ${SCRIPT}
date


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


mails=$(echo "${MAILACCOUNT} franz.seefried@qualitasag.ch")


if [ -z $1 ]; then
    echo "brauche den Code welches System zurueckgemeldet werden werden soll"
    exit 1
fi

breed=${1}

#mail 
for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: Final Summary and Screening of Logfile done for ${breed}

Dear colleague,

1) Strong request to check the following file

$LOG_DIR/${1}.LogScreening.${run}.log

since relevant information from $LOG_DIR is collected inside of this file.

2) !!!Be Happy!!!... since you have achieved to finish 50Kimputing.


echo " "
fsf, Qualitas AG, Switzerland" | ssmtp ${person}

done





date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

