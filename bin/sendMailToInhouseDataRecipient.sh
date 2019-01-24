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
elif [ ${1} == "BSW" ] ; then
        mails=$(echo "katrin.haab@braunvieh.ch michaela.glarner@braunvieh.ch mirjam.spengeler@qualitasag.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch urs.schnyder@qualitasag.ch juerg.moll@qualitasag.ch")
elif [ ${1} == "HOL" ] ; then
	mails=$(echo "Emilie.Boillat@swissherdbook.ch elvina.huguenin@swissherdbook.ch alex.barenco@swissherdbook.ch mirjam.spengeler@qualitasag.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch urs.schnyder@qualitasag.ch juerg.moll@qualitasag.ch")
elif [ ${1} == "VMS" ] ; then
	mails=$(echo "svenja.strasser@mutterkuh.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch urs.schnyder@qualitasag.ch juerg.moll@qualitasag.ch")
else
	echo " $1 != VMS / HOL, ich stoppe"
	exit 1
fi

breed=$1

if [ -z $2 ]; then
    echo "brauche den Code welches File verarbeitet wurde und im Mail erwaehnt werden soll"
    exit 1
fi



for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: ${breed} CHE Logfile ${1}_SammelLOG-${run}.csv Imputation wurde abgelegt in dsch/in

Liebe(r) Kollege(in),

LOGfile ist ${1}_SammelLOG-${run}.csv


VG Qualitas AG" | ssmtp ${person}

done





date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

