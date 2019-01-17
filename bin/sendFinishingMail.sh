#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW ${SCRIPT}
echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################

if [ -z $1 ]; then
    echo "brauche den Code welches Programm gelaufen ist"
    exit 1
elif [ -z $2 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'ALL'"
    exit 1
else


echo "To: ${MAILACCOUNT}
From: ${MAILACCOUNT}
Subject: ...Programm ${1} finished for ${2}...

Programm fertig" | ssmtp ${MAILACCOUNT}

fi


echo " "
RIGHT_END=$(date)
echo $RIGHT_END ${SCRIPT}
