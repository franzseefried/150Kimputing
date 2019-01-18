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
outtime=$(date +"%d%m%Y")

echo "TVD;SEXPEDI;SEXTEST;GeneSeekChip;GrenzeSex;VALUESexFromGenotype;ErrorCode" > ${ZOMLD_DIR}/${run}.BADsexCheck.lst

#ls -trl ${LAB_DIR}/*
#echo " "
#echo "loeschen der leeren files now"
for file in $( find ${LAB_DIR}/*) ; do
    if [ ! -s ${file} ] ; then
       rm -f  ${file};
    fi;
done
#echo " "
#ls -trl ${LAB_DIR}/*

#define breed loop
cd ${LAB_DIR}
filearray=$(find -maxdepth 1 -type f -exec basename {} \;)
breedarray=$(echo $filearray | awk '{for(i=1;i<=NF;i++) print substr($i,1,3)}'| sort -T ${SRT_DIR} -T ${SRT_DIR} -u -r) 

#validate breedarray
valbreed=$(echo "BSW HOL VMS")
for i in $(echo ${breedarray}); do
if [[ "${valbreed}" == *"${i}"* ]]; then
   echo YES ${i} > /dev/null
else
   echo "OOOPS ich habe Rassenkuerzel die nicht zulaessig sind: ${i}"
   echo "mindestens 1 file in ${LAB_DIR} hat Inhalt und ist weder BSW_, HOL_, oder VMS_:"
   ls -trl 
   echo "ich stoppe"
   exit 1
fi
done


#loeschen der leeren files:
for i in $(echo ${breedarray}); do
if ! find ${LAB_DIR}/ -maxdepth 0 -empty | read v; then
    for file in $( find ${LAB_DIR}/${i}*) ; do
        if [ ! -s ${file} ] ; then
           rm -f ${file};
        fi;
    done
fi
done

#process data now
for rasse in $breedarray ; do
#for rasse in BSW; do
for labfile in $(ls ${rasse}*) ; do
   if [[ ${labfile} == *Qualitas* ]]; then
    ll=$(echo $labfile | sed 's/\.tvd\.toWorkWith//g' | cut -d'-' -f2- )
    awk '{print $2}' $labfile | sort -T ${SRT_DIR} -T ${SRT_DIR} -u -T $SRT_DIR > $TMP_DIR/${ll}.tiere.toWorkWithII
  else
    ll=$(echo $labfile | sed 's/\.tvd\.toWorkWith//g' | sed 's/\.built/ /g' | cut -d' ' -f1 | cut -d'-' -f2-)
    awk '{print $2}' $labfile | sort -T ${SRT_DIR} -T ${SRT_DIR} -u -T $SRT_DIR > $TMP_DIR/${ll}.tiere.toWorkWithII
  fi
  nSNPfile=$(echo $CHCK_DIR/${run}/nSNPs.check.${ll} )
  ls -trl $nSNPfile
  tierefile=$TMP_DIR/${ll}.tiere.toWorkWithII
  ls -trl $tierefile

  echo " "
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
  
  if [ ${rasse} == "BSW" ]; then
  	aimfolder=bvch
  fi
  if [ ${rasse} == "HOL" ]; then
  	aimfolder=shb
  fi
  if [ ${rasse} == "VMS" ]; then
   aimfolder=vms
  fi

  #die neuen Chips haben alle Y-Chr SNPs die alten nicht, darum brauch es bei den alten Chips den Sexcheck via PAR und bei den neuen Chips den Sexcheck via YChr
  colCHIP=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')
  colSEXCHECK=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep SexCheckStrat | awk '{print $1}')
  colGESE=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep GeneSeekCode | awk '{print $1}')
  sexSTRAT=$(awk -v cc=${colCHIP} -v dd=${colSEXCHECK} -v ee=${chip} 'BEGIN{FS=";"}{if( $cc == ee ) print $dd }' ${REFTAB_CHIPS})
  gesecode=$(awk -v cc=${colCHIP} -v dd=${colGESE} -v ee=${chip} 'BEGIN{FS=";"}{if( $cc == ee ) print $dd }' ${REFTAB_CHIPS})


  join -t' ' -o'1.1 2.1' -a1 -1 1 -2 2 <(sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 ${tierefile}) <(awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f1-2 | tr ';' ' ' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k2,2) | sort -T ${SRT_DIR} -T ${SRT_DIR} -u > $TMP_DIR/sexcheck.id.lst.${labfile}
  nNULL=$(awk '{if($2 == "") print}' $TMP_DIR/sexcheck.id.lst.${labfile} | wc -l | awk '{print $1}')
  if [ ${nNULL} -gt 0 ]; then echo "mindestens ein Tier ist nicht in $WORK_DIR/animal.overall.info -> IDANIMAL == NULL which is not allowed"; exit 1; fi 
  nover=$(wc -l $TMP_DIR/sexcheck.id.lst.${labfile} | awk '{print $1}' )
  if [ ${nover} -gt 0 ]; then
#########################################################
  echo "SEXCHECK started effectively"
  nanimal=$(awk 'END{print NR}' $TMP_DIR/sexcheck.id.lst.${labfile} )
  #echo ${nanimal}
  runs_ani=$(awk '{print $1}' $TMP_DIR/sexcheck.id.lst.${labfile} | tr '\n' ' ' )
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
  echo "-t ${muni} -l ${labfile} -f ${sexSTRAT} -g ${gesecode}"
  nohup ${BIN_DIR}/runSexCheck.sh -t ${muni} -l ${labfile} -f ${sexSTRAT} -g ${gesecode} > $LOG_DIR/${muni}.${labfile}.SEXCHECK.log 2>&1 &
  pid=$!
#  echo $pid
  pids=(${pids[@]} $pid)
  nJobs=$(($nJobs+1))
  done



#check if all animals have been analyzed
for allanicheck in ${runs_ani}; do
LASTANIcheck $TMP_DIR/${allanicheck}.${labfile}.sexcheck
done
fi
done
done
rm -f $TMP_DIR/sexcheck.id.lst.*
rm -f $TMP_DIR/*.tiere.toWorkWithII
#sammeln aller die den sexhcheck nicht erfuellen und schreiben der ergebnisliste
cd ${MAIN_DIR}
awk 'BEGIN{FS=";";OFS=";"}{if($7 == "Y") print $0}'  ${TMP_DIR}/*.sexcheck >> ${ZOMLD_DIR}/${run}.BADsexCheck.lst
cd ${lokal}
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

