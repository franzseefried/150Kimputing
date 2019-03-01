#!/bin/bash
RIGHT_NOW=$(date +"%x %r %Z")
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " " 
##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
fi

set -o errexit
set -o nounset
breed=${1}
cat $WORK_DIR/ped_umcodierung.txt.${breed} | tr ' ' ';' > $TMP_DIR/ped_umcodierung.txt.${breed}.smcl

if [ ${GWASPHEN} == "BINARY" ]; then
  (awk '{print substr($0,1,14)}' $GWAS_DIR/${breed}_${GWAStrait}_controlAnimals.txt;
   awk '{print substr($0,1,14)}' $GWAS_DIR/${breed}_${GWAStrait}_affectedAnimals.txt) | sort -k1,1 |\
  join -t' ' -o'2.1 1.1' -1 1 -2 5 - <(sort -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed} ) > $TMP_DIR/${breed}.aff.con.txt
fi
if [ ${GWASPHEN} == "QUANTITATIVE" ]; then
  join -t' ' -o'2.1 1.1' -1 1 -2 5 <(sort -t' ' -k1,1 $GWAS_DIR/${breed}_${GWAStrait}_inputPhenotypes.txt)  <(sort -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}) > $TMP_DIR/${breed}.aff.con.txt 
fi

(awk '{if(NR == 1) print}'  $TMP_DIR/${breed}.genotypes.dat; 
awk 'BEGIN{FS=" ";OFS=" "}{ \
   if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$1]=$2;}} \
   else {sub("\015$","",$(NF));PCI="0";PCI=PC[$1]; \
   if   (PCI != "") {print $0}}}' $TMP_DIR/${breed}.aff.con.txt $TMP_DIR/${breed}.genotypes.dat ) | awk '{printf "%-8s%s\n", $1,$2}' > $TMP_DIR/${breed}.genotypes.txt
mv $TMP_DIR/${breed}.genotypes.txt $TMP_DIR/${breed}.genotypes.dat

wc -l $TMP_DIR/${breed}.genotypes.dat


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}


