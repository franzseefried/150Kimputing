#!/bin/bash 
SCRIPT=`basename ${BASH_SOURCE[0]}`
RIGHT_NOW=$(date)
echo $RIGHT_NOW Start ${SCRIPT}
date


##############################################################
lokal=$(pwd | awk '{print $1}')
source  /qualstore03/data_zws/snp/50Kimputing/parfiles/steuerungsvariablen.ctr.sh
###############################################################

mails=$(echo "marina.kraus@qualitasag.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
#mails=$(echo "franz.seefried@qualitasag.ch")



if [ -z $1 ]; then
    echo "brauche den Code welches Daten zurueckgemeldet werden werden sollen"
    exit 1
fi



#mail 
for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: externe SNP-files Imputing ${run} enthalten in file:


$1 


Imputing-Team, Qualitas AG, Zug" | ssmtp ${person}

done





date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

