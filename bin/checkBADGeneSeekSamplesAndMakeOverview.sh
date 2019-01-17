#!/bin/bash 
SCRIPT=`basename ${BASH_SOURCE[0]}`
RIGHT_NOW=$(date)
echo $RIGHT_NOW Start ${SCRIPT}
date


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################

mails=$(echo "marina.kraus@qualitasag.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
#mails=$(echo "franz.seefried@qualitasag.ch")



#if test -s $LOG_DIR/masterskriptHandleNewSNPdata.log && test -s $LOG_DIR/skript1.log ; then
nBAD=$(awk '{if($0 ~ "OOOPS") print}' $LOG_DIR/masterskriptHandleNewSNPdata.log |cut -d':' -f2|cut -d' ' -f1 | sort -T ${SRT_DIR} -u |wc -l | awk '{print $1}')
nALL=$(awk '{if($0 ~ "Printing Sum of all newly delivered GeneSeek samples across all chips") print $13}' $LOG_DIR/skript1.log)
#echo $nBAD $nALL
echo "##############################"
PropBad=$(echo $nBAD $nALL |awk '{print "Proportion of rejected samples: "($1/$2)*100}' | awk '{print $5}')

echo "##############################"

echo "#####################################################"
echo "print summary No of rejected samples across breeding organisations and chips"
RP=$(awk '{if($0 ~ "OOOPS") print}' $LOG_DIR/masterskriptHandleNewSNPdata.log  | cut -d':' -f2 | cut -d' ' -f1 | sort -T ${SRT_DIR} -u |while read line; do grep $line $WRK_DIR/crossref.txt ; done | cut -d';' -f2-6,16,25 | sed 's/ //g' |sort|uniq -c |\
  sort -T ${SRT_DIR} -k1,1nr | awk '{print $1,$2}' | sed 's/\;/ /5' | sed 's/\;/ /5' | awk '{print $1"_"$3"_"$4,$2}' | sed 's/_ /_/g' | tr ' ' ';' |\
  awk 'BEGIN{FS=";"}{if($2 ~ "X")print $1,"150K";if($3 ~ "X")print $1,"HD";if($4 ~ "X")print $1,"LD";if($6 ~ "X")print $1,"F250K"}' | tr '_' ' ' | awk '{printf "%-20s%-20s%-10s%+15s\n", $1,$2,$3,$4}')
echo "#####################################################"

for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: Report of rejected samples during processing data

Dear colleague,

in ${run} a proportion of ${PropBad}% was rejected due to quality issues.

###############################
Distribution across chips,sampleType and breeding organisation:
${RP}
###############################

Kind regards, Qualitas AG, Switzerland" | ssmtp ${person}

done


#fi


cd ${lokal}
date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

