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
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
else
set -o errexit
set -o nounset
breed=${1}

for i in VATER MUTTER; do
join -t';' -1 1 -2 1 -v1 -o'1.1 1.2 1.3 1.4' <(sort -t';' -k1,1  $ZOMLD_DIR/ALL_Korrektueren${i}.csv) <(sort -t';' -k1,1  $ZOMLD_DIR/BSW_Korrektueren${i}.csv) |\
sort -t';' -k1,1 | join -t';' -1 1 -2 1 -v1 -o'1.1 1.2 1.3 1.4' - <(sort -t';' -k1,1  $ZOMLD_DIR/HOL_Korrektueren${i}.csv ) |\
sort -t';' -k1,1 | join -t';' -1 1 -2 1 -o'1.1 1.2 1.3 1.4' -v1 - <(sort -t';' -k1,1  $ZOMLD_DIR/VMS_Korrektueren${i}.csv ) > $TMP_DIR/ALL.${i}.Kor.txt

(echo "Tier;VaterALT;flag;VaterNEU";
cat $TMP_DIR/ALL.${i}.Kor.txt) > $ZOMLD_DIR/ALL_Korrektueren${i}.csv
done



fi



echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
