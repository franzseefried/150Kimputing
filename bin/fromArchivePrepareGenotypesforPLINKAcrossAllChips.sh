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
	zofol=$(echo "bvch")
fi
if [ ${1} == "HOL" ]; then
	zofol=$(echo "shb")
fi
if [ ${1} == "VMS" ]; then
        zofol=$(echo "vms")
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

#idUmcodierung idanimal zu PediID
awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | awk 'BEGIN{FS=";"}{print $1";"$2}' | sed 's/ //g' | tr ';' ' '  > $TMP_DIR/umcd.lst1



#define breed loop
colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ImputationDensityLD150K | awk '{print $1}')
colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')


CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v densit=${dichte} 'BEGIN{FS=";"}{if( $cc == densit ) print $dd }' ${REFTAB_CHIPS})
lgtC=$(echo ${CHIPS} | wc -w | awk '{print $1}')
if [ ${lgtC} -eq 0 ]; then
  echo "keie Chips angegeben in ${REFTAB_CHIPS} in Kolonne ImputationDensityLD150K "
  exit 1
fi

HDprocess () {
pids=
echo "HDdata now"
for chip in ${CHIPS} ; do
  echo "${chip} for ${breed}"
  (
  cd $SNP_DIR/dataWide${chip}/${zofol}
  linkarray=$(find -maxdepth 1 -type l -exec basename {} \;)
  echo $linkarray | tr ' ' '\n' | grep [0-9] > $TMP_DIR/linkarray.${breed}.${chip}.lst
  if test -s  $TMP_DIR/linkarray.${breed}.${chip}.lst; then  wc -l $TMP_DIR/linkarray.${breed}.${chip}.lst; fi
  for lin in ${linkarray}; do
     $BIN_DIR/awk_buildPLINKpedfile $TMP_DIR/umcd.lst1 $WORK_DIR/ped_umcodierung.txt.${breed} ${lin}
  done > $WORK_DIR/${breed}.${chip}.ped
  )&
  pid=$!
  pids=(${pids[@]} $pid)
  #echo ${pids[@]}
done
sleep 23
echo "Here ar the jobids of the stated Jobs HD"
echo ${pids[@]}
nJobs=$(echo ${pids[@]} | wc -w | awk '{print $1}')
echo "Waiting till ped.files are set up"
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



LDprocess (){
pids=
echo "LDdata now"
for chip in ${CHIPS} ; do
  echo "${chip} for ${breed}"
  (
  cd $SNP_DIR/dataWide${chip}/${zofol}
  linkarray=$(find -maxdepth 1 -type l -exec basename {} \;)
  echo $linkarray | tr ' ' '\n' | grep [0-9] > $TMP_DIR/linkarray.${breed}.${chip}.lst
  if test -s  $TMP_DIR/linkarray.${breed}.${chip}.lst; then  wc -l $TMP_DIR/linkarray.${breed}.${chip}.lst; fi
  for lin in ${linkarray}; do
     $BIN_DIR/awk_buildPLINKpedfile $TMP_DIR/umcd.lst1 $WORK_DIR/ped_umcodierung.txt.${breed} ${lin}
  done > $WORK_DIR/${breed}.${chip}.ped
  )&
  pid=$!
  pids=(${pids[@]} $pid)
  #echo ${pids[@]}
done
sleep 23
echo "Here ar the jobids of the stated Jobs LD"
echo ${pids[@]}
nJobs=$(echo ${pids[@]} | wc -w | awk '{print $1}')
echo $nJobs
echo "Waiting till ped.files are set up"
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


echo "####################################"
echo "Call function ${2}process now"
echo " "
${2}process
echo "####################################"
echo " "
echo " "
echo "####################################"
echo " "
echo "${2} ped files exist: postprocessing"
echo " "
echo "####################################"
for chip in ${CHIPS} ; do
  if test -s $WORK_DIR/${breed}.${chip}.ped; then
    echo " "
    echo "$chip binaries are set up"
    $FRG_DIR/plink --ped $WORK_DIR/${breed}.${chip}.ped --map $WORK_DIR/${breed}.${chip}.map --missing-genotype '0' --cow --nonfounders --noweb --make-bed --out $TMP_DIR/${breed}.${chip}
    cp $TMP_DIR/${breed}.${chip}* $BCP_DIR/${run}/binaryfiles/.
    rm -f $WORK_DIR/${breed}.${chip}.ped
    echo " "
  else
    CHIPS=$(echo $CHIPS | awk  -v pihc=${chip} '{for(i = 1; i <= NF; i=i+1) if($i != pihc) print $i}');
  fi
done

cd $START_DIR




echo "####################################"
echo " "
echo "${2} union datasets within density"
echo " "
echo "####################################"
lgtCHIP=$(echo ${CHIPS} | wc -w | awk '{print $1}')
lgtCHIPmax=$(echo ${lgtCHIP} | awk '{print $1-1}');
if [ ${lgtCHIPmax} -eq 0 ]; then
   nochp=1
   chipEINS=$(echo ${CHIPS} | awk -v cci=${nochp} '{print $cci}')
   fileEINS=${breed}.${chipEINS}
   outfile=${breed}${dichte}
   echo $fileEINS
   #$FRG_DIR/plink --bfile $TMP_DIR/${fileEINS} --nonfounders --cow --noweb --recode --make-bed --out $TMP_DIR/${outfile}
   $FRG_DIR/plink --bfile $TMP_DIR/${fileEINS} --nonfounders --cow --noweb --make-bed --out $TMP_DIR/${outfile}
   echo " "
else
for nochp in $(seq 1 1 ${lgtCHIPmax}); do
  sleep 10
  if [ ${nochp} -eq 1 ]; then
     chipEINS=$(echo ${CHIPS} | awk -v cci=${nochp} '{print $cci}')
     chipNEXT=$(echo ${CHIPS} | awk -v cci=${nochp} '{cccci=cci+1;print $cccci}')
     fileEINS=${breed}.${chipEINS}
     fileNEXT=${breed}.${chipNEXT}
     if [ ${nochp} -eq ${lgtCHIPmax} ]; then
        outfile=${breed}${dichte}
     else
        outfile=${breed}.CHIPmerge.${dichte}
     fi
     echo " "
     echo $fileEINS $fileNEXT
#     $FRG_DIR/plink --bfile $TMP_DIR/${fileEINS} --bmerge $TMP_DIR/${breed}.${chipNEXT} --nonfounders --cow --noweb --recode --make-bed --out $TMP_DIR/${outfile}
     $FRG_DIR/plink --bfile $TMP_DIR/${fileEINS} --bmerge $TMP_DIR/${fileNEXT} --nonfounders --cow --noweb --make-bed --out $TMP_DIR/${outfile}
     echo " "
  else
     fileEINS=${breed}.CHIPmerge.${dichte}
     chipNEXT=$(echo ${CHIPS} | awk -v cci=${nochp} '{cccci=cci+1;print $cccci}')
     fileNEXT=${breed}.${chipNEXT}
     #echo $nochp $lgtCHIP
     if [ ${nochp} -eq ${lgtCHIPmax} ]; then
        outfile=${breed}${dichte}
     else
        outfile=${breed}.CHIPmerge.${dichte}
     fi
     echo " "
     echo $fileEINS $fileNEXT $outfile
     #$FRG_DIR/plink --bfile $TMP_DIR/${fileEINS} --bmerge $TMP_DIR/${breed}.${chipNEXT} --nonfounders --cow --noweb --recode --make-bed --out $TMP_DIR/${outfile}
     $FRG_DIR/plink --bfile $TMP_DIR/${fileEINS} --bmerge $TMP_DIR/${fileNEXT} --nonfounders --cow --noweb --make-bed --out $TMP_DIR/${outfile}
     echo " "
  fi
done
fi




echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
