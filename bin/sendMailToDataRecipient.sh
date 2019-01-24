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
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL'"
    exit 1
elif [ ${1} == "HOL" ] ; then
	mails=$(echo "genotype@holstein.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch urs.schnyder@qualitasag.ch juerg.moll@qualitasag.ch")
elif [ ${1} == "VMS" ] ; then
	mails=$(echo "svenja.strasser@mutterkuh.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch urs.schnyder@qualitasag.ch juerg.moll@qualitasag.ch")
else
	echo " $1 != VMS / HOL, ich stoppe"
	exit 1
fi

breed=$1

if [ -z $2 ]; then
    echo "brauche den Code welches File verarbeitet wurde und im Mail erwaehnt werden soll"
    exit 1
fi

#mail to EDV Qualitas
if [ ${1} == "HOL" ];then
for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: ${breed} CHE Logfile ${1}_SammelLOG-${run}.csv Imputation was uploaded to your ftpServer

Dear colleague,

LOGfile is ${1}_SammelLOG-${run}.csv


Kind regards, Qualitas AG, Switzerland" | ssmtp ${person}

done
fi




date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

