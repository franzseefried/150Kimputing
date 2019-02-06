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
    echo "brauche den Dateinamen welche gemeldet werden werden werden soll"
    exit 1
fi

ifile=${1}

#mail 
for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: Missing file in SNPpipeline

Dear colleague,

1) Strong request to check the following file

${ifile}

It has not been prepared, but it is required.

Pipeline won't be processed successfully :-()

echo " "
fsf, Qualitas AG, Switzerland" | ssmtp ${person}

done





date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

