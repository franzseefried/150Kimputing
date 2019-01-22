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


#skript basiert auf dem output von SNPrelship analyses!!!
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




#wenn $LOG_DIR/${breed}.GRM.SMP1101.log ready ist, sind auch die anderen benoetigten files ready!!!

#fuer alle Tiere im Genofile soll der F geholt werden
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));G[$1]=substr($2,1,1);}} \
    else {sub("\015$","",$(NF));E=G[$1]; \
    if   (E != "") {print $1,$1}}}' $SMS_DIR/${breed}.SNP1101FImpute.geno $WRK_DIR/Run${run}.alleIDS_${breed}.txt > $SMS_DIR/${breed}.Fg.toBechecked


echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^run pairwise GRM calculation for ${breed}"
cat $PAR_DIR/SNP1101_FgRMpair.ctr | sed "s/WWWWWWWWWW/${breed}/g" > $SMS_DIR/${breed}.FgRMpair.use
rm -rf $SMS_DIR/${breed}-FgRM-pair
mkdir -p $SMS_DIR/${breed}-FgRM-pair
cd $SMS_DIR

$FRG_DIR/snp1101 $SMS_DIR/${breed}.FgRMpair.use 2>&1 > $LOG_DIR/${breed}.FgRMpair.SMP1101.log

echo " "
echo "pairwise Relationship-coefficients are ready now:"
ls -trl $SMS_DIR/${breed}-FgRM-pair/pair_rsh.txt


echo " "
echo "write files like it was before for Genomic and Pedigree Inbreeding"
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));G[$1]=$5;}} \
    else {sub("\015$","",$(NF));E=G[$1];F=G[$2]; \
    if   (E != "" && F != "") {print E,F,$3}}}' $WRK_DIR/Run${run}.alleIDS_${breed}.txt $SMS_DIR/${breed}-FgRM-pair/pair_rsh.txt > $RES_DIR/${breed}.PedigreeFcoefficient.${run}.txt

awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));G[$1]=$5;}} \
    else {sub("\015$","",$(NF));E=G[$1];F=G[$2]; \
    if   (E != "" && F != "") {print E,F,$4}}}' $WRK_DIR/Run${run}.alleIDS_${breed}.txt $SMS_DIR/${breed}-FgRM-pair/pair_rsh.txt > $RES_DIR/${breed}.GenomicFcoefficient.${run}.txt

rm -rf $SMS_DIR/${breed}-FgRM-pair


echo " "
RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}
