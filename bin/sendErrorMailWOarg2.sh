#!/bin/bash
RIGHT_NOW=$(date +"%x %r %Z")
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
Subject: ...OOOPS Error occured in programm ${1} ...

Masterskript stops: check and clarify!!!" | ssmtp ${MAILACCOUNT}

fi


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

