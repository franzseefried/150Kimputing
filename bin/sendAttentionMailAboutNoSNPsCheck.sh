#!/bin/bash 
SCRIPT=`basename ${BASH_SOURCE[0]}`
RIGHT_NOW=$(date)
echo $RIGHT_NOW Start ${SCRIPT}
date


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parFiles/steuerungsvariablen.ctr.sh
###############################################################


mails=$(echo ${MAILACCOUNT})


if [ -z $1 ]; then
    echo "brauche den Code welches Labfile zurueckgemeldet werden werden soll"
    exit 1
fi

labfile=${1}

#mail 
for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: ${labfile} is suspicious

Dear colleague,

${labfile} does not have a uniq No. of SNPs for all samples.

Reject ${labfile} manually.

Reorder new labfile in the lab.

Restart process.


echo " "
Kind regards, Qualitas AG, Switzerland" | ssmtp ${person}

done





date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

