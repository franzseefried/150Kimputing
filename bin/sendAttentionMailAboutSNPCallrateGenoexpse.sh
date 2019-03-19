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
#mails="franz.seefried@qualitasag.ch"
mails=$(echo "franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")

if [ -z $2 ]; then
    echo "brauche den Anteil an Proben die die Untergrenze nciht erfuellen"
    exit 1
fi
if [ -z $3 ]; then
    echo "brauche die Untergrnze der GenoExPSE callrate"
    exit 1
fi

#mail 
for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: Attention!!! high proportion of low-callrate SNPs amoung GenoExPSE SNPs

Dear colleague,

callrate at GenoExPSE SNPs was checked at SNPs using Samples that passed quality control based on chip data.
 
A set of ${2} SNPs has a callrate below ${3}, which is highly suspicious. 

File with calculated callrates is ${HIS_DIR}/\*.${run}.GenoExPSEsnp.SNPclrt
Format: SNPname CallrateISAGgenoeExPSE

Talk to fsf.

NOTE: report this observation to the breesing company otherwise this information is not reported back to the customer.


Kind regards, Qualitas AG, Switzerland" | ssmtp ${person}

done





date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

