#!/bin/bash 
SCRIPT=`basename ${BASH_SOURCE[0]}`
RIGHT_NOW=$(date)
echo $RIGHT_NOW Start ${SCRIPT}
date


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################

if [ -z $1 ]; then
    echo "brauche den Code welches File verarbeitet wurde"
    exit 1
fi
mails="franz.seefried@qualitasag.ch"
#mails=$(echo "franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")

if [ -z $2 ]; then
    echo "brauche den Anteil an Proben die die Untergrenze nciht erfuellen"
    exit 1
fi

#mail 
for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: Attention!!! samples are included inside ${1} without chipcallrate or No. of SNPs

Dear colleague,

in total a sum of ${2} samples inside ${1} are inlcuded without chipcallrate or No. of SNPs.

-> Check and talk to fsf before data is imported into ARGUS.


NOTE: report this observation to the breesing company otherwise this information is not reported back to the customer.


Kind regards, Qualitas AG, Switzerland" | ssmtp ${person}

done





date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

