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
    if(FILENAME==ARGV[2]){if(NR>0){sub("\015$","",$(NF));OP[$1]=$1}} \
    else {sub("\015$","",$(NF));ECS=NP[$13];ECD=NP[$15]; OCD=OP[$2];\
    if ((ECS != "" || ECD != "") && $12 != 0 && $14 != 0 && OCD == "") {print "#G",$0}}}' $TMP_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt $TMP_DIR/${breed}.samplesNGPlook.pedigreeOffspring ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv|wc -l | awk '{print $1}') 


if [ ${nHistBad} -gt 0 ]; then
susHisSam=$(awk 'BEGIN{FS=";";OFS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));NP[$1]=$1}} \
    if(FILENAME==ARGV[2]){if(NR>0){sub("\015$","",$(NF));OP[$1]=$1}} \
    else {sub("\015$","",$(NF));ECS=NP[$13];ECD=NP[$15]; OCD=OP[$2];\
    if ((ECS != "" || ECD != "") && $12 != 0 && $14 != 0 && OCD == "") {print $2}}}' $TMP_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt $TMP_DIR/${breed}.samplesNGPlook.pedigreeOffspring ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv)

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
