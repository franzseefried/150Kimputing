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



pids=
for RMtype in TWIN; do 
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^run TWINsearch calculation for ${breed}"
cat $PAR_DIR/SNP1101_${RMtype}.ctr | sed "s/WWWWWWWWWW/${breed}/g" > $SMS_DIR/${breed}.${RMtype}.use
rm -rf $SMS_DIR/${breed}-${RMtype}
mkdir -p $SMS_DIR/${breed}-${RMtype}
cd $SMS_DIR
(
$FRG_DIR/snp1101 $SMS_DIR/${breed}.${RMtype}.use 2>&1 > $LOG_DIR/${breed}.${RMtype}.SMP1101.log
)&
pid=$!
pids=(${pids[@]} $pid)
cd ${MAIN_DIR}
pwd
date
done
cd $lokal
echo "Here ar the jobids of the stated SNP1101-Jobs"
echo ${pids[@]}
echo " "
nJobs=$(echo ${pids[@]} | wc -w | awk '{print $1}')
echo "Waiting till TWINjob is finished"
while [ $nJobs -gt 0 ]; do
  pids_old=${pids[@]}
  pids=
  nJobs=0
  for pid in ${pids_old[@]}; do
    if kill -0 $pid > /dev/null 2>&1; then # kill -0 $pid ist true falls der Job noch laeuft
      nJobs=$(($nJobs+1))
      pids=(${pids[@]} $pid)
    fi
  done
  sleep 60
done

if test -s $SMS_DIR/${breed}-TWIN/identical.txt; then 
echo "IdenticalSerach is ready now:"
ls -trl $SMS_DIR/${breed}-TWIN/identical.txt
sed 's/\t/ /g' $SMS_DIR/${breed}-TWIN/identical.txt > $SMS_DIR/${breed}-TWIN/identical.sed
#make list for Logfile
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));G[$1]=$5;}} \
    else {sub("\015$","",$(NF));E=G[$1]; F=G[$2];\
    if   (E != "" && F!= "") {print E,F,$5/100}}}' $WRK_DIR/Run${run}.alleIDS_${breed}.txt $SMS_DIR/${breed}-TWIN/identical.sed > $RES_DIR/${breed}.SNPtwins.${run}.txt
else
echo "IdenticalSerach did not detect identical genotypes"
echo "a a" > $RES_DIR/${breed}.SNPtwins.${run}.txt
fi
rm -f $SMS_DIR/${breed}-TWIN/identical.sed

echo " "
RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}
