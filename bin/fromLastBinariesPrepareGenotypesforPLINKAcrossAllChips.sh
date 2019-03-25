#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options bsw, hol or vms"
  echo "Usage: $SCRIPT -c <string>"
  echo "  where <string> specifies the Density: e.g. LD / HD"
  echo "Usage: $SCRIPT -d <string>"
  echo "  where <string> specifies the Imputation level: e.g. LD150KImputation"
  exit 1
}
### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi
while getopts :b:c:d: FLAG; do
  case $FLAG in
    b) # set option "b"
      export breed=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${breed} == "BSW" ] || [ ${breed} == "HOL" ] || [ ${breed} == "VMS" ]; then
          echo ${breed} > /dev/null
      else
          usage "Breed not correct, must be specified: bsw / hol / vms using option -b <string>"
          exit 1
      fi
      ;;
    c) # set option "c"
      export dichte=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${dichte} == "HD" ] || [ ${dichte} == "LD" ]; then
          echo ${dichte} > /dev/null
      else
          usage "Dichte not correct, must be specified: bsw / hol / vms using option -b <string>"
          exit 1
      fi
      ;;
    d) # set option "d"
      export SNPlevel=$(echo $OPTARG)
      ;;
     *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that breed is not empty
if [ -z "${breed}" ]; then
      usage 'breed not specified, must be specified using option -b <string>'   
fi
if [ -z "${dichte}" ]; then
      usage 'Dichte not specified, must be specified using option -c <string>'   
fi
if [ -z "${SNPlevel}" ]; then
      usage 'code for SNPlevel not specified, must be specified using option -d <string>'   
fi
START_DIR=$(pwd)
set -o errexit
set -o nounset
if [ ${breed} == "BSW" ]; then
	zofol=$(echo "bvch")
fi
if [ ${breed} == "HOL" ]; then
	zofol=$(echo "shb")
fi
if [ ${breed} == "VMS" ]; then
    zofol=$(echo "vms")
fi

#define last imputation timestamp
#TimeStampLastImp=$(stat -c "%y" /qualstore03/data_archiv/zws/150Kimputing/${oldrun}/binaryfiles | awk '{print $1}' | sed 's/\-//g')
TimeStampLastImp=$(stat -c "%y" $WRK_DIR/Run${oldrun}.alleIDS_${breed}.txt  | awk '{print $1}' | sed 's/\-//g')

#idUmcodierung idanimal zu PediID
awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | awk 'BEGIN{FS=";"}{print $1";"$2}' | sed 's/ //g' | tr ';' ' '  > $TMP_DIR/umcd.lst1



#define breed loop
colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ${SNPlevel} | awk '{print $1}')
colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')


CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v densit=${dichte} 'BEGIN{FS=";"}{if( $cc == densit ) print $dd }' ${REFTAB_CHIPS})
lgtC=$(echo ${CHIPS} | wc -w | awk '{print $1}')
if [ ${lgtC} -eq 0 ]; then
  echo "keie Chips angegeben in ${REFTAB_CHIPS} in Kolonne  ${IMPUTATIONFLAG} "
  exit 1
fi

HDprocess () {
pids=
echo "HDdata now"
for chip in ${CHIPS} ; do
  echo "${chip} for ${breed}"
  (
  cd $SNP_DIR/dataWide${chip}/${zofol}
  linkarray=$(find -maxdepth 1 -type l | xargs ls -l --time-style="+%Y%m%d" | awk -v tsmplimp=${TimeStampLastImp} '{if($6 > tsmplimp)print $7}')
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
  linkarray=$(find -maxdepth 1 -type l | xargs ls -l --time-style="+%Y%m%d" | awk -v tsmplimp=${TimeStampLastImp} '{if($6 > tsmplimp)print $7}')
  echo $linkarray | tr ' ' '\n' | grep [0-9]  > $TMP_DIR/linkarray.${breed}.${chip}.lst
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
echo "Call function ${dichte}process now"
echo " "
echo "Attention: I collect links that are younger than ${TimeStampLastImp}"
echo " "
${dichte}process
echo "####################################"
echo " "
echo " "
echo "####################################"
echo " "
echo "${dichte} ped files exist: postprocessing"
echo " "
echo "####################################"
#loesche Tiere die in die Liste eingetragen worden sind dass sie unlinked worden sind. Achtung file aus dem OLDRUN da ids noch nicht upgedated sind

if test -s ${HIS_DIR}/UnlinkedAnimalsfor.${run}.txt; then
for chip in ${CHIPS} ; do
   join -t' ' -o'1.1' -1 6 -2 1 <(awk '{if($6 != "-") print}' $WRK_DIR/Run${oldrun}.alleIDS_${breed}.txt |sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k6,6) <(awk -v cc=${chip} '{if($2 == cc) print}' ${HIS_DIR}/UnlinkedAnimalsfor.${run}.txt |sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1) | awk '{print "1",$1}' > $TMP_DIR/${breed}.unlkd.ids.${oldrun}.${run}.${chip}
   if test -s $TMP_DIR/${breed}.unlkd.ids.${oldrun}.${run}.${chip}; then
     mkdir -p $TMP_DIR/${oldrun}/binaryfiles/
     echo " "
   if test -s $BCP_DIR/${oldrun}/binaryfiles/${breed}.${chip}.bed ;then
     echo "$chip :.......1........ remove unlinked animals in old binary: see $TMP_DIR/${breed}.unlkd.ids.${oldrun}.${run}.${chip}"
     $FRG_DIR/plink --bfile $BCP_DIR/${oldrun}/binaryfiles/${breed}.${chip} --missing-genotype '0' --remove $TMP_DIR/${breed}.unlkd.ids.${oldrun}.${run}.${chip} --cow --nonfounders --noweb --make-bed --out $TMP_DIR/${oldrun}/binaryfiles/${breed}.${chip}
     mv $TMP_DIR/${oldrun}/binaryfiles/${breed}.${chip}* $BCP_DIR/${oldrun}/binaryfiles/.
     echo " "
   else
     echo "echo $chip :.......1........ nothing to do due to empty binary file $BCP_DIR/${oldrun}/binaryfiles/${breed}.${chip}.bed for ${breed}" 
   fi
   else
     echo "$chip :.......1........ nothing to do due to empty $TMP_DIR/${breed}.unlkd.ids.${oldrun}.${run}.${chip}"
   fi
done
else
     echo "$chip :.......1........ nothing to do due to empty ${HIS_DIR}/UnlinkedAnimalsfor.${run}.txt"
fi


#loesche Tiere die im alten Pedigree drin waren, nicht aber mehr im neuen pedigree. bsp BV Tier das wegen HOL synch ploetzlich HOL wurde und deswegen aus der BV imp raus geflogen ist CH 120.1251.0227.3./// diese in allen chip binaries loeschen!!!
join -t' ' -o'1.1' -v1 -1 6 -2 6 <(awk '{if($6 != "-") print}' $WRK_DIR/Run${oldrun}.alleIDS_${breed}.txt | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k6,6 ) <(awk '{if($6 != "-") print}' $WRK_DIR/Run${run}.alleIDS_${breed}.txt | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k6,6 ) | awk '{print "1",$1}' > $TMP_DIR/${breed}.lst.ids.${oldrun}.${run}
if test -s $TMP_DIR/${breed}.lst.ids.${oldrun}.${run} ; then
mkdir -p $TMP_DIR/${oldrun}/binaryfiles/
for chip in ${CHIPS} ; do
     echo " "
     if test -s $BCP_DIR/${oldrun}/binaryfiles/${breed}.${chip}.bed; then
        echo "$chip :.......2........ remove lost animals in old binary due to pedigree issues in new run: see $TMP_DIR/${breed}.lst.ids.${oldrun}.${run} Attention sample may be present in another chipbinary since they are removed across all chips"
        $FRG_DIR/plink --bfile $BCP_DIR/${oldrun}/binaryfiles/${breed}.${chip} --missing-genotype '0' --remove $TMP_DIR/${breed}.lst.ids.${oldrun}.${run} --cow --nonfounders --noweb --make-bed --out $TMP_DIR/${oldrun}/binaryfiles/${breed}.${chip}
        mv $TMP_DIR/${oldrun}/binaryfiles/${breed}.${chip}* $BCP_DIR/${oldrun}/binaryfiles/.
     echo " "
     fi
done
else
     echo "$chip :.......2........ nothing to do due to empty $TMP_DIR/${breed}.lst.ids.${oldrun}.${run}"
fi



#loesche Tiere die schon den selben genotyp hatten wie er neu nochmal rein gekommen ist. Achtung file aus dem OLDRUN da ids noch nicht upgedated sind
if test -s ${HIS_DIR}/ReplacedAnimals.${run}.txt; then
for chip in ${CHIPS} ; do
   join -t' ' -o'1.1' -1 6 -2 1 <(awk '{if($6 != "-") print}' $WRK_DIR/Run${oldrun}.alleIDS_${breed}.txt |sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k6,6) <(awk -v cc=${chip} '{if($2 == cc) print}' ${HIS_DIR}/ReplacedAnimals.${run}.txt |sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1) | awk '{print "1",$1}' > $TMP_DIR/${breed}.rplcd.ids.${oldrun}.${run}.${chip}
   if test -s $TMP_DIR/${breed}.rplcd.ids.${oldrun}.${run}.${chip}; then
     mkdir -p $TMP_DIR/${oldrun}/binaryfiles/
     echo " "
     if test -s $BCP_DIR/${oldrun}/binaryfiles/${breed}.${chip}.bed; then
        echo "$chip :.......3........ remove replaced animals in old binary: animals which had in oldrun already same chipdensity as in current run new data came into: see $TMP_DIR/${breed}.rplcd.ids.${oldrun}.${run}.${chip}"
     $FRG_DIR/plink --bfile $BCP_DIR/${oldrun}/binaryfiles/${breed}.${chip} --missing-genotype '0' --remove $TMP_DIR/${breed}.rplcd.ids.${oldrun}.${run}.${chip} --cow --nonfounders --noweb --make-bed --out $TMP_DIR/${oldrun}/binaryfiles/${breed}.${chip}
     mv $TMP_DIR/${oldrun}/binaryfiles/${breed}.${chip}* $BCP_DIR/${oldrun}/binaryfiles/.
     else
     echo 
        echo "$chip :.......3........ nothing to do due to empty $BCP_DIR/${oldrun}/binaryfiles/${breed}.${chip}.bed"
     fi
     echo " "
   else
     echo "$chip :.......3........ nothing to do due to empty $TMP_DIR/${breed}.rplcd.ids.${oldrun}.${run}.${chip}"
   fi
done
else
     echo "$chip :.......3........ nothing to do due to empty ${HIS_DIR}/ReplacedAnimals.${run}.txt"
fi




#update idimputing im alten binary
join -t' ' -o'1.1 2.1 1.5 2.5' -1 6 -2 6 <(awk '{if($6 != "-") print}' $WRK_DIR/Run${oldrun}.alleIDS_${breed}.txt |sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k6,6) <(awk '{if($6 != "-") print}' $WRK_DIR/Run${run}.alleIDS_${breed}.txt |sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k6,6) | awk '{print "1",$1,"1",$2}' > $TMP_DIR/${breed}.update.ids.${oldrun}.${run}
for chip in ${CHIPS} ; do
  if test -s $BCP_DIR/${oldrun}/binaryfiles/${breed}.${chip}.bed; then
    echo " "
    echo "$chip :.......4........ update idimputing in old binary"
    $FRG_DIR/plink --bfile $BCP_DIR/${oldrun}/binaryfiles/${breed}.${chip} --missing-genotype '0' --update-ids $TMP_DIR/${breed}.update.ids.${oldrun}.${run} --cow --nonfounders --noweb --make-bed --out $BCP_DIR/${oldrun}/binaryfiles/${run}.${breed}.${chip}
    echo " "
  #else
    #update $CHIPS in vorberetung des naechsten schritts
    #CHIPS=$(echo $CHIPS | awk  -v pihc=${chip} '{for(i = 1; i <= NF; i=i+1) if($i != pihc) print $i}');
  fi
done




#make binaries new added samples and merge them with binaries from last run. put into new binary archive and also TMPdir
echo ${CHIPS}
for chip in ${CHIPS} ; do
  if test -s $WORK_DIR/${breed}.${chip}.ped; then
    echo " "
    echo "$chip :.......5........ new samples create new binary. Store in $BCP_DIR/${run}/binaryfiles as well as in $TMP_DIR/"
    $FRG_DIR/plink --ped $WORK_DIR/${breed}.${chip}.ped --map $WORK_DIR/${breed}.${chip}.map --missing-genotype '0' --cow --nonfounders --noweb --make-bed --out $TMP_DIR/${breed}.${chip}
    echo " "
    echo "$chip :.......5........ neue proben liefern binary && altes binary aus dem oldrun existiert -> merge them"
    if test -s $BCP_DIR/${oldrun}/binaryfiles/${run}.${breed}.${chip}.bed; then
        $FRG_DIR/plink --bfile $BCP_DIR/${oldrun}/binaryfiles/${run}.${breed}.${chip} --bmerge $TMP_DIR/${breed}.${chip} --missing-genotype '0' --cow --nonfounders --noweb --make-bed --out $BCP_DIR/${run}/binaryfiles/${breed}.${chip}
    else
      echo " "
      echo "$chip :.......5........ neue proben liefern binary && altes binary aber gibt es nicht"
        $FRG_DIR/plink --bfile $TMP_DIR/${breed}.${chip} --missing-genotype '0' --cow --nonfounders --noweb --make-bed --out $BCP_DIR/${run}/binaryfiles/${breed}.${chip}
    fi
    cp $BCP_DIR/${run}/binaryfiles/${breed}.${chip}* $TMP_DIR/.
    rm -f $WORK_DIR/${breed}.${chip}.ped
    #loeschen in old2folder
    rm -f $BCP_DIR/${old2run}/binaryfiles/${breed}.${chip}*
    echo " "
  else
    if test -s $BCP_DIR/${oldrun}/binaryfiles/${run}.${breed}.${chip}.bed; then
       echo " "
       echo "$chip :.......5........ neue proben liefern kein binary altes binary existiert"
       $FRG_DIR/plink --bfile $BCP_DIR/${oldrun}/binaryfiles/${run}.${breed}.${chip} --missing-genotype '0' --cow --nonfounders --noweb --make-bed --out $BCP_DIR/${run}/binaryfiles/${breed}.${chip}
       cp $BCP_DIR/${run}/binaryfiles/${breed}.${chip}* $TMP_DIR/.
    else
       echo " "
       echo "$chip :.......5........ weder neues noch altes binary existiert"
        #for endung in bed bim fam log hh;do
        #   touch $BCP_DIR/${run}/binaryfiles/${breed}.${chip}.${endung}
        #done
       #remove chip from array in vorbereitung des nächsten schritts, dem union
       CHIPS=$(echo $CHIPS | awk  -v pihc=${chip} '{for(i = 1; i <= NF; i=i+1) if($i != pihc) print $i}');
    fi
    rm -f $WORK_DIR/${breed}.${chip}.ped
  fi
done


cd $START_DIR



echo "####################################"
echo " "
echo "${dichte} union datasets within density"
echo ${CHIPS}
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
