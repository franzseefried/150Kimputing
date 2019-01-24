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
START_DIR=$(pwd)


if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
elif [ ${1} == "BSW" ] || [ ${1} == "HOL" ]  || [ ${1} == "VMS" ]; then

if [ ${1} == "BSW" ]; then
	zofol=$(echo "intergenomics")
fi
if [ ${1} == "HOL" ]; then
	zofol=$(echo "cdcb anafi")
fi
if [ ${1} == "VMS" ]; then
    zofol=$(echo "interbeef")
fi
else 
  echo "unbekannter Systemcode BSW VMS oder HOL erlaubt"
  exit 1
fi


if [ -z $2 ]; then
   echo "brauche den Code für die Chipdichte HD oder LD"
   exit 1
elif [ $2 == "LD" ] || [ $2 == "HD" ]; then
   echo $2 > /dev/null
   dichte=${2}
else
   echo "Der Code fuer die Chipdichte muss LD oder HD sein, ist aber ${2}"
   exit 1
fi


set -o nounset
breed=${1}



#define breed loop
colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ImputationDensityLD150K | awk '{print $1}')
colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')


CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v densit=${dichte} 'BEGIN{FS=";"}{if( $cc == densit ) print $dd }' ${REFTAB_CHIPS})
lgtC=$(echo ${CHIPS} | wc -w | awk '{print $1}')
if [ ${lgtC} -eq 0 ]; then
  echo "keie Chips angegeben in ${REFTAB_CHIPS} in Kolonne ImputationDensityLD150K "
  exit 1
fi

HDextsnp () {
pids=
echo "HDdata now"
for chip in ${CHIPS} ; do
  echo "${chip} for ${breed}"
for zf in ${zofol} ; do
  (
  cd $ARCH_DIR/dataWide${chip}/${zf}
  reqID=$(awk '{ sub("\r$", ""); print }' ${BIGPAR_DIR}/RefTabGenomSelIDadresse.txt | awk -v r=${zf} 'BEGIN{FS=";"}{if($2 == r) print $1}')
  filearray=$(find -maxdepth 1 -type f -exec basename {} \;)
  for fil in ${filearray}; do
    echo $fil | cut -d'.' -f2 | awk -v rr=${reqID} '{print $1,rr}' 
  done > $TMP_DIR/${breed}.${chip}.${zf}.externeSNPHD.lst
  )&
  pid=$!
  pids=(${pids[@]} $pid)
  #echo ${pids[@]}
done
done
sleep 23
echo "Here ar the jobids of the stated Jobs HD"
echo ${pids[@]}
nJobs=$(echo ${pids[@]} | wc -w | awk '{print $1}')
echo "Waiting till lists are set up"
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
}



LDextsnp (){
pids=
echo "LDdata now"
for chip in ${CHIPS} ; do
  echo "${chip} for ${breed}"
for zf in ${zofol} ; do
  (
  cd $ARCH_DIR/dataWide${chip}/${zf}
  reqID=$(awk '{ sub("\r$", ""); print }' ${BIGPAR_DIR}/RefTabGenomSelIDadresse.txt | awk -v r=${zf} 'BEGIN{FS=";"}{if($2 == r) print $1}')
  filearray=$(find -maxdepth 1 -type f -exec basename {} \;)
  for fil in ${filearray}; do
    echo $fil | cut -d'.' -f2 | awk -v rr=${reqID} '{print $1,rr}'
  done > $TMP_DIR/${breed}.${chip}.${zf}.externeSNPLD.lst
  )&
  pid=$!
  pids=(${pids[@]} $pid)
  #echo ${pids[@]}
done
done
sleep 23
echo "Here ar the jobids of the stated Jobs LD"
echo ${pids[@]}
nJobs=$(echo ${pids[@]} | wc -w | awk '{print $1}')
echo $nJobs
echo "Waiting till lists are set up"
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
}


####################################
#Aufruf der Funktion here
${2}extsnp
####################################


if ! test -s ${RES_DIR}/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt; then touch ${RES_DIR}/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt; fi
if ! test -s ${RES_DIR}/${breed}.newANIMALS.in${oldrun}_imVglmit${old2run}.txt; then touch ${RES_DIR}/${breed}.newANIMALS.in${oldrun}_imVglmit${old2run}.txt; fi 
cd $START_DIR


#LD / HD.union lists innerhalb snp-dichte und schreiben mit TVD inkl Reduktion auf die die zum ersten mal dabei sind
cat $TMP_DIR/${breed}.*.*.externeSNP${dichte}.lst | sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'2.2 1.2 2.3' -1 1 -2 1 - <(awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | awk 'BEGIN{FS=";"}{print $1";"$2";"$3}' | sed 's/ //g' | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k1,1 ) |\
tee $TMP_DIR/${breed}.externeSNP${dichte}.lst |\
sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 1.3' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 ${RES_DIR}/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt ) |\
sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.NEWexterneSNP${dichte}.${run}.lst
 
cat $TMP_DIR/${breed}.*.*.externeSNP${dichte}.lst | sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'2.2 1.2 2.3' -1 1 -2 1 - <(awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | awk 'BEGIN{FS=";"}{print $1";"$2";"$3}' | sed 's/ //g' | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k1,1 ) |\
sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 1.3' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 ${RES_DIR}/${breed}.newANIMALS.in${oldrun}_imVglmit${old2run}.txt ) |\
sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.NEWexterneSNP${dichte}.${oldrun}.lst

rm -f $TMP_DIR/${breed}.*.*.externeSNPHD.lst
rm -f $TMP_DIR/${breed}.*.*.externeSNPHD.lst
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
