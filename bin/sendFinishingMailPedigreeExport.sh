#!/bin/bash 
SCRIPT=`basename ${BASH_SOURCE[0]}`
RIGHT_NOW=$(date)
echo $RIGHT_NOW Start ${SCRIPT}
date


##############################################################
cd /qualstore03/data_zws/snp/150Kimputing
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################

#mails=$(echo "franz.seefried@qualitasag.ch")
mails=$(echo ${MAILZWS}";max.reich@qualitasag.ch;"${MAILACCOUNT} | tr ';' ' ')



#mail 
for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: Pedigree-Export beendet auf ${dbsystem} im Rahmen der Imputation

Job auf Oberflaeche nun wieder frei gegeben.

Imputing-Team, Qualitas AG, Zug" | ssmtp ${person}

done





date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

