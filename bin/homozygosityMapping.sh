#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

#############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit
set -o nounset


####ACHTUNG: es gibt probleme wenn zu viele Tiere drin sind in higher/lower.animals.${breed}!!!!!!
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
#set -o nounset

#calculate max no of allowed of heterozygous calls; y
#not yet implemented


#schreiben der Genotypen hier, seletktion der Tiere weiter unten:
ls -trl $TMP_DIR/${breed}.${GWAStrait}.genotypes*
#https://www.cog-genomics.org/plink/1.9/ibd
#for i in $(seq 0 1 10); do
for i in 2 ; do
echo "--homozyg-window-het is defined as ${i}"
echo " "
$FRG_DIR/plink --ped $TMP_DIR/${breed}.${GWAStrait}.genotypes.ped  --map $TMP_DIR/${breed}.${GWAStrait}.genotypes.map --cow --homozyg-snp 200 --homozyg group --homozyg-density 100 --homozyg-gap 1800 --homozyg-window-het ${i} --homozyg-window-missing 0 --out ${HOM_DIR}/${breed}.Homozyg_${GWAStrait} 


cat  $GWAS_DIR/${breed}_${GWAStrait}_affectedAnimals.txt |awk 'FNR==NR {x3[$1]=$1;x2[$1]=$2; next}
$1 in x3 {print ("1",x2[$1])}
' <(awk '{print $5,$1}' ${WORK_DIR}/ped_umcodierung.txt.${breed}.updated) - > ${HOM_DIR}/${breed}.cases_${GWAStrait}.phen

cat  $GWAS_DIR/${breed}_${GWAStrait}_controlAnimals.txt |awk 'FNR==NR {x3[$1]=$1;x2[$1]=$2; next}
$1 in x3 {print ("1",x2[$1])}
' <(awk '{print $5,$1}' ${WORK_DIR}/ped_umcodierung.txt.${breed}.updated) - > ${HOM_DIR}/${breed}.controls_${GWAStrait}.phen

cp $TMP_DIR/${breed}.${GWAStrait}.genotypes.map $HOM_DIR/${breed}.${GWAStrait}.map 
nSNPs=$(wc -l $HOM_DIR/${breed}.${GWAStrait}.map | awk '{print $1}')
echo $nSNPs
Rscript ${BIN_DIR}/plotROH.R ${GWAStrait} ${HOM_DIR} ${breed} ${nSNPs}
done
rm -f $HOM_DIR/${breed}.${GWAStrait}.map 



echo " "
RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}
