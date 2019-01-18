#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit
#############################################
#function to check competeness of data prep
LASTANIcheck () {
existshot=N 
existresult=Y
while [ ${existshot} != ${existresult} ]; do
if test -s ${1}  ; then
RIGHT_NOW=$(date +"%x %r %Z")
existshot=Y
fi  
done
echo "file to check  ${1}  exists ${RIGHT_NOW}, check if it is ready"
shotcheck=same
shotresult=unknown
current=$(date +%s)
while [ ${shotcheck} != ${shotresult} ]; do
 lmod=$(stat -c %Y ${1} )
 RIGHT_NOW=$(date +"%x %r %Z")
 #echo $current $lmod
 if [ ${lmod} > 60 ]; then
    shotresult=same
    echo "${1} is ready now ${RIGHT_NOW}"
 fi 
done    
}
#############################################

outtime=$(date +"%x" | awk 'BEGIN{FS="/"}{print $1$2$3}')

#######Funktionsdefinition
getColmnNrSemicl () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(head -1 $2 | tr ';' '\n' | grep -n "^$1$" | awk -F":" '{print $1}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}
##########################



cd $LAB_DIR
for labfile in $(ls Qualitas*toWorkWith) ; do
  getColmnNrSemicl QuagCode ${REFTAB_CHIPS}; colcc=${colNr_};
  getColmnNrSemicl IntergenomicsCode ${REFTAB_CHIPS}; coldd=${colNr_};
  ll=$(echo $labfile | sed 's/\.tvd\.toWorkWith//g' )
  nSNPfile=$(echo $CHCK_DIR/${run}/nSNPs.check.${ll} )
#  ls -trl $nSNPfile
  tierefile=$TMP_DIR/${ll}.tiere.toWorkWith
#  ls -trl ${tierefile}
  labfileout=$(echo ${labfile} | sed 's/\.tvd//g')
#for labfile in $(ls BSW*toWorkWith) ; do
  nSNP=$(wc -l ${labfile} | awk '{print $1}')
  if [ ${nSNP} -eq 0 ]; then
	rm -f ${labfile}
  else
  echo "Frage chip ab an Hand des ersten Tieres fuer ${labfile}"
  animal=$(awk '{if(NR == 1)print $1}' ${tierefile})
  v=$(awk -v ani=${animal} '{if($1 == ani) print $2 }' ${nSNPfile} )

  if [ ${v} -eq 54609 ]; then
     chip=50KV2
   elif [ ${v} -eq 54001 ]; then
     chip=50KV1
   elif [ ${v} -gt 2900 ] && [ ${v} -lt 6001 ]; then
     chip=03KV1
   elif [ ${v} -gt 8700 ] && [ ${v} -lt 8801 ]; then
     chip=09KV1
   elif [ ${v} -gt 8800 ] && [ ${v} -lt 19001 ]; then
     chip=09KV2
   elif [ ${v} -gt 19000 ] && [ ${v} -lt 26001 ]; then
     chip=20KV1
   elif [ ${v} -gt 6000 ] && [ ${v} -lt 8701 ]; then
     chip=LDV1
   elif [ ${v} -gt 26000 ] && [ ${v} -lt 30001 ]; then
     chip=26KV1
   elif [ ${v} -gt 30000 ] && [ ${v} -lt 36001 ]; then
     chip=30KV1
   elif [ ${v} -gt 36000 ] && [ ${v} -lt 50001 ]; then
     chip=47KV1
   elif [ ${v} -gt 70000 ] && [ ${v} -lt 80000 ]; then
     chip=77KV1
   elif [ ${v} -gt 138000 ] && [ ${v} -lt 150000 ]; then
     chip=150KV1
   elif [ ${v} -gt 221114 ] && [ ${v} -lt 221116 ]; then
     chip=F250V1
   elif [ ${v} -gt 700000 ] && [ ${v} -lt 800000 ]; then
     chip=777KV1
   else
     echo "ooops komischer chip"
     exit 1
   fi

if [[ ${labfile} == *Qualitas* ]]; then
ll=$(echo $labfile | sed 's/\.tvd\.toWorkWith//g' )
else
echo "${labfile} was selected to prepare 70%ITB data which is not correct"
exit 1
fi
nSNPfile=$(echo $CHCK_DIR/${run}/nSNPs.check.${ll} )


  ##prep map:
  imap=$(awk -v cc=${colcc} -v dd=${coldd} -v hh=${chip} 'BEGIN{FS=";"}{if($cc == hh) print $dd}' ${REFTAB_CHIPS})
  awk '{ sub("\r$", ""); print }' $MAP_DIR/intergenomics/SNPindex_${imap}_new_order.txt | sed 's/Dominant Red/Dominant_Red/g' |  awk '{print $1,$2,$3}' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/MAP${imap}.srt  
  nmap=$(wc -l $TMP_DIR/MAP${imap}.srt | awk '{print $1}')


  join -t' ' -o'1.1 2.1' -1 1 -2 2 <(sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 ${tierefile}) <(awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f1-2 | tr ';' ' ' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k2,2) | sort -T ${SRT_DIR} -T ${SRT_DIR} -u > $TMP_DIR/intergenomics.id.lst.${labfile}
nover=$(wc -l $TMP_DIR/intergenomics.id.lst.${labfile} | awk '{print $1}' )
if [ ${nover} -gt 0 ]; then
#########################################################
echo "705 prep started effectively"
nanimal=$(awk 'END{print NR}' $TMP_DIR/intergenomics.id.lst.${labfile} )
#echo ${nanimal}
runs_ani=$(awk '{print $1}' $TMP_DIR/intergenomics.id.lst.${labfile} | tr '\n' ' ' )
pids=
nJobs=0
for muni in ${runs_ani[@]}; do
#echo $muni
  while [ $nJobs -ge $numberOfParallelRJobs ]; do
    pids_old=${pids[@]}
    pids=
    nJobs=0
    for pid in ${pids_old[@]}; do
      if kill -0 $pid > /dev/null 2>&1; then # kill -0 $pid ist true falls der Job noch laeuft
        nJobs=$(($nJobs+1))
        pids=(${pids[@]} $pid)
      fi
    done
    sleep 10
  done
  echo "-t ${muni} -l ${labfile} -i ${imap} -n ${nmap} -c ${chip} -o ${outtime} -a ${labfileout}"
  nohup ${BIN_DIR}/run705prep.sh -t ${muni} -l ${labfile} -i ${imap} -n ${nmap} -c ${chip} -o ${outtime} -a ${labfileout} > $LOG_DIR/${muni}.${labfile}.705prep.log 2>&1 &
  pid=$!
#  echo $pid
  pids=(${pids[@]} $pid)
  nJobs=$(($nJobs+1))
done



#check if all animals have been analyzed
for allanicheck in ${runs_ani}; do
idin=$(awk -v m=${allanicheck} '{if($1 == m) print $2}' $TMP_DIR/intergenomics.id.lst.${labfile} )
LASTANIcheck $ITL_DIR/${chip}/705.${idin}.${chip}.${outtime}.${labfileout} 
done

fi
fi
done



cd ${lokal}
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
