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
echo " "
echo "http://zzz.bwh.harvard.edu/plink/anal.shtml"
$FRG_DIR/plink --ped $TMP_DIR/${breed}.${GWAStrait}.genotypes.ped  --map $TMP_DIR/${breed}.${GWAStrait}.genotypes.map --cow --model --out ${GWAS_DIR}/${breed}.Assoc_${GWAStrait} 

echo " "
echo "plot results"
Rscript ${BIN_DIR}/plotPLINKgwasResult.R ${breed} $GWAS_DIR/${breed}.Assoc_${GWAStrait}.model ${TMP_DIR}/${breed}.${GWAStrait}.genotypes.map ${GWAS_DIR} ${GWAStrait}



echo " "
RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}
