#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################

if [ -z $1 ]; then
    echo "brauche den Code welches Programm gelaufen ist"
    exit 1
else


echo "To: ${MAILACCOUNT}
From: ${MAILACCOUNT}
Subject: ...Programm ${1} finished ...

Programm fertig" | ssmtp ${MAILACCOUNT}

fi


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}


