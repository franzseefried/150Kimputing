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
Subject: ...I suggest that you have a look into ${LOG_DIR}/${1}.LogScreening.${run}.log 

If everything looks ok inside there, feel free an import $ZOMLD_DIR/${1}_SammelLOG-${run}.csv into ARGUS.

and start calcVRDGGOZW-prediction.

Scripte here are still running, SingleGene pipeline, Imputation acc pipeline, so LogCSreeneing will be done later again.

Have fun :-) fsf" | ssmtp ${MAILACCOUNT}




echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT} 


