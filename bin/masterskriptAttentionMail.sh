#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


#run one anial against all genotyped animals to search closest SNP-relatives
# Kommandozeilenargumenten einlesen und pruefen
if test -z $1; then
  echo "FEHLER: Kein Argument erhalten. Diesem Shell-Script muss ein Rassenkuerzel mitgegeben werden! --> PROGRAMMABBRUCH"
  exit 1
fi
breed=$(echo $1 | awk '{print toupper($1)}')
if [ ${breed} != "BSW" ] && [ ${breed} != "HOL" ] && [ ${breed} != "VMS" ]; then
  echo "FEHLER: Diesem shell-Script wurde ein unbekanntes Rassenkuerzel uebergeben! (BSW / HOL / VMS sind zulaessig) --> PROGRAMMABBRUCH"
  exit 1
fi


nHistBad=$(awk 'BEGIN{FS=";";OFS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));NP[$1]=$1}} \
    else {sub("\015$","",$(NF));ECD="0";ECD=NP[$2]; \
    if (ECD != "") {print "#F",$0}}}' $TMP_DIR/${breed}.samplesWiGPar ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv | awk 'BEGIN{FS=";"}{if($9 != "" || $10 != "" || $11 != "" || $12 != "" || $13 != "" || $14 != "" || $15 != "" || $16 != "") print}' |wc -l | awk '{print $1}') 


if [ ${nHistBad} -gt 0 ]; then
susHisSam=$(awk 'BEGIN{FS=";";OFS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));NP[$1]=$1}} \
    else {sub("\015$","",$(NF));ECD="0";ECD=NP[$2]; \
    if (ECD != "") {print "#F",$0}}}' $TMP_DIR/${breed}.samplesWiGPar ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv | awk 'BEGIN{FS=";"}{if($9 != "" || $10 != "" || $11 != "" || $12 != "" || $13 != "" || $14 != "" || $15 != "" || $16 != "") print $3}')

for indi in ${susHisSam}; do
mailheader=$(awk 'BEGIN{FS=";";OFS=";"}{if(NR == 1) print $0}' ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv)
mailtextOLD=$(awk -v ii=${indi} 'BEGIN{FS=";";OFS=";"}{if($2 == ii) print $0}' ${HIS_DIR}/${breed}_SumUpLOG.${oldrun}.csv)
mailtext=$(awk -v ii=${indi} 'BEGIN{FS=";";OFS=";"}{if($2 == ii) print $0}' ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv)
#echo ${indi} ${mailtext} ${mailheader}
$BIN_DIR/sendAttentionMailAboutPedigreeMutationsAmoungHistoricSamples.sh ${1} ${indi} ${mailtext} ${mailheader} ${mailtextOLD}
done
fi


echo " ";
RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}
