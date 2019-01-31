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
	mails=$(echo "michaela.glarner@braunvieh.ch katrin.haab@braunvieh.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
	#mails=$(echo "franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
elif [ ${1} == "HOL" ] ; then
	mails=$(echo "genotype@holstein.ch alex.barenco@siwssherdbook.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
	#mails=$(echo "franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
elif [ ${1} == "VMS" ] ; then
	mails=$(echo "franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch svenja.strasser@mutterkuh.ch")
        #mails=$(echo "franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
else
	echo " $1 != VMS / HOL, ich stoppe"
	exit 1
fi

breed=$1

if [ -z $2 ]; then
    echo "brauche den Code welches Tier zurueckgemeldet werden werden soll"
    exit 1
fi
if [ -z $3 ]; then
    echo "brauche den Text der zurueckgemeldet werden werden soll"
    exit 1
fi
if [ -z $4 ]; then
    echo "brauche den Header der zurueckgemeldet werden werden soll"
    exit 1
fi
if [ -z $5 ]; then
    echo "brauche den Text aus dem Alten SumUplog der zurueckgemeldet werden werden soll"
    exit 1
fi
#mail 
for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: ${breed} CHE Sample ${2} jetzt suspekt

Dear colleague,

Mindesten ein Elter gemaess Pedigree von ${2} wurde nun typisiert.

Basierend auf den nun vorhandenen Genotypen ist die Probe ${2} jetzt suspekt. Siehe folgende Zeile:

${4}
old:
${5}
now:
${3}

Script for identification does not distunguish between sex pf parents. So please check and verify.
NOTE: report this observation to the breesing company otherwise this information is not reported back to the customer.
echo " "
echo " "
Kind regards, Qualitas AG, Switzerland" | ssmtp ${person}

done





date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

