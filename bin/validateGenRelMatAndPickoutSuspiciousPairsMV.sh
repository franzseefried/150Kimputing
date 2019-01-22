#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit
set -o nounset

#alle Tiere auswerten, trennen nach Rasse
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


#erstelle Liste mit den Tieren deren Mutter genotypisiert ist, da diese unten dan negativ gejoint werden

join -t' ' -o'1.1 1.2 2.2 2.3' -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/${breed}Typisierungsstatus${run}.txt) <(awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f2,7,12 | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k1,1) |\
           sort -T ${SRT_DIR} -t' ' -k3,3 |\
           join -t' ' -o'1.1 1.2 1.3 2.2 1.4' -e'-' -a1 -1 3 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/${breed}Typisierungsstatus${run}.txt) |\
           sort -T ${SRT_DIR} -t' ' -k5,5 |\
           join -t' ' -o'1.1 1.2 1.3 1.4 1.5 2.2' -e'-' -a1 -1 5 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/${breed}Typisierungsstatus${run}.txt) |\
           awk '{if($6 != "-") print}' > $TMP_DIR/${breed}.samplesWithGenotypedDams.toReduceFromMVcheck.lst


#inkl reduktion auf typiserte Dams im Datensatz
 join -t' ' -o'1.1 1.2 1.3' -v1 -1 1 -2 1 <(awk -v bbb=${minplausibleMVrelship} '{if($5 < bbb) print $1,$3,$5}' ${RES_DIR}/${breed}.out.AnimalMV.snp1101.${run}.txt | sort -T ${SRT_DIR} -t' ' -k1,1	) <(awk '{print $1" ok"}' $WRK_DIR/${breed}_MVOK.default.lst | sort -T ${SRT_DIR} -t' ' -k1,1 ) |\
    sort -T ${SRT_DIR} -t' ' -k1,1 |\
    join -t' ' -o'1.1 1.2 1.3' -v1 -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.samplesWithGenotypedDams.toReduceFromMVcheck.lst) > $ZOMLD_DIR/${breed}_suspiciousMVs.${run}.csv

if ! test -s $ZOMLD_DIR/${breed}_suspiciousMVs.${run}.csv;then
echo "c c" > $ZOMLD_DIR/${breed}_suspiciousMVs.${run}.csv
fi
rm -f $TMP_DIR/${breed}.samplesWithGenotypedDams.toReduceFromMVcheck.lst
echo " "
RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}

