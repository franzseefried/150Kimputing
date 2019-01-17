#!/bin/bash 
SCRIPT=`basename ${BASH_SOURCE[0]}`
RIGHT_NOW=$(date)
echo $RIGHT_NOW Start ${SCRIPT}
date


##############################################################
lokal="/qualstore03/data_zws/snp/50Kimputing"
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################

mails=$(echo "genotype@holstein.ch alex.barenco@siwssherdbook.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")

breed=HOL

if [ -z $1 ]; then
    echo "brauche den Code welches file zurueckgemeldet werden werden soll"
    exit 1
fi

if [ -z $2 ]; then
    echo "brauche den Code welches Tier zurueckgemeldet werden werden soll"
    exit 1
fi

if [ -z $3 ]; then
    echo "brauche den Code welche Chipdichte das Tier im aktuellen Datensatz hat"
    exit 1
fi


#mail 
for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: ${breed} Sample ${2}: externes SNP-file wurde geloescht

Lieber Kollege,

fuer das Tier wurden SNP-Daten abgegeben: ${1}. 

Diese wurden nicht ins System uebernommen, da das Tiere bereits ein Imputationsergebnis hat:

Tier: ${2}  

Chipdichte im System: ${3}

Wir bitten um Kenntnisnahme. 


Beste Gruesse, Qualitas AG, Zug" | ssmtp ${person}

done





date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

