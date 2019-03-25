#!/bin/bash 
SCRIPT=`basename ${BASH_SOURCE[0]}`
RIGHT_NOW=$(date)
echo $RIGHT_NOW Start ${SCRIPT}
date


##############################################################
lokal=$(pwd | awk '{print $1}')
source  /qualstore03/data_zws/snp/150Kimputing/parfiles/steuerungsvariablen.ctr.sh
###############################################################

#mails=$(echo "franz.seefried@qualitasag.ch")
mails=$(echo ${MAILZWS}";max.reich@qualitasag.ch;"${MAILACCOUNT} | tr ';' ' ')
echo $mails



#mail 
for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: Pedigree-Export gestartet auf ${dbsystem} im Rahmen der Imputation

Kein Export von der Oberflaeche aus moeglich bis zum finishing mail


Imputing-Team, Qualitas AG, Zug" | ssmtp ${person}

done





date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

