#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW STart ${SCRIPT} 
echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################




echo "To: ${MAILACCOUNT}
From: ${MAILACCOUNT}
Subject: ...I suggest that you start now ${PROG_DIR}/superMasterskript.sh for BSW / HOL / VMS...

If you are in a hurry, you can start now ${PROG_DIR}/superMasterskript.sh although I have now finished completely.

If you have time go our for a drink and wait until ${PROG_DIR}/masterskriptHandleNewSNPdata.sh has finished completely.

I suggest to run HOL on castor at least. For BSW and VMS your are free in your decision.

Enjoy whatever you decide. :-) fsf" | ssmtp ${MAILACCOUNT}




echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT} 


