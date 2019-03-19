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

(cat $WRK_DIR/BSWTypisierungsstatus${oldrun}.txt;
    cat $WRK_DIR/HOLTypisierungsstatus${oldrun}.txt;
    cat $WRK_DIR/VMSTypisierungsstatus${oldrun}.txt;) > $WORK_DIR/Typisierungsstatuslastimputing.txt
#(cat ${HDD_DIR}/BSWTypisierungsstatus${oldrun}.txt;
#    cat ${HDD_DIR}/HOLTypisierungsstatus${oldrun}.txt) > $WORK_DIR/Typisierungsstatuslastimputing.txt
#rm -f ${HIS_DIR}/ReplacedAnimals.${run}.txt
touch ${HIS_DIR}/ReplacedAnimals.${run}.txt
cd $LAB_DIR
for labfile in $( ls ); do
if [[ ${labfile} == *Qualitas* ]]; then
ll=$(echo $labfile | sed 's/\.tvd\.toWorkWith//g' )
else
ll=$(echo $labfile | sed 's/\.tvd\.toWorkWith//g' | sed 's/\.built/ /g' | cut -d' ' -f1 | cut -d'-' -f2-)
awk '{print $2}' $labfile | sort -T ${SRT_DIR} -T ${SRT_DIR} -u > $TMP_DIR/${ll}.tiere.toWorkWith
fi
nSNPfile=$(echo $CHCK_DIR/${run}/nSNPs.check.${ll} )
#ls -trl $nSNPfile
tierefile=$TMP_DIR/${ll}.tiere.toWorkWith
#ls -trl $tierefile
echo $labfile
  getColmnNrSemicl QuagCode ${REFTAB_CHIPS}; colcc=${colNr_};
  getColmnNrSemicl IntergenomicsCode ${REFTAB_CHIPS}; coldd=${colNr_};
  echo "checke an Hand der Anzahl SNP den Chip fuer jedes Tier in ${labfile}"
  for animal in $(cat ${tierefile}) ; do
  v=$(awk -v ani=${animal} '{if($1 == ani) print $2 }' ${nSNPfile} )
  #echo $animal $v
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
     echo "ooops komischer chip: ${v}"
     exit 1
  fi


  idanimal=$(awk -v ani=${animal} 'BEGIN{FS=";"}{if($2 == ani) print $1}' $WORK_DIR/animal.overall.info | sed 's/ //g' )
  existingDICHTE=$(awk -v ani=${animal} 'BEGIN{FS=" "}{if($1 == ani) print $2}' $WORK_DIR/Typisierungsstatuslastimputing.txt | sed 's/DB/HD/g' )
  #nur wenn das Tier schon da ist
  if [ ! -z ${existingDICHTE} ]; then
  if [ -z ${idanimal} ];then echo "$animal fehlt in $WORK_DIR/animal.overall.info"; exit 1; fi
  
  
  #define Chipdichte
  colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')
  colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ${IMPUTATIONFLAG} | awk '{print $1}')
  incomingdichte=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v ee=${chip} 'BEGIN{FS=";"}{if( $dd == ee ) print $cc }' ${REFTAB_CHIPS})
  #echo "$idanimal # ${existingDICHTE} # ${incomingdichte} ${chip}"
  #wenn neue incoming chipdichte gleich ist wie existing chipdichte, dann unlink
  if [ ${existingDICHTE} == ${incomingdichte} ] && [ ${chip} == "F250V1" ]; then
  for system in bvch shb vms; do
  llll=$SNP_DIR/dataWide${chip}/${system}/${idanimal}.lnk
      if test -s  ${llll}; then
        filelinked=$(ls -l ${llll} | awk '{print $NF}')
        echo ${llll} is unlinked from ${filelinked}
        unlink ${llll}
        echo ${idanimal} ${chip} >> ${HIS_DIR}/ReplacedAnimals.${run}.txt
      fi
  done
  else
  CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v ee=${incomingdichte} 'BEGIN{FS=";"}{if( $cc == ee ) print $dd }' ${REFTAB_CHIPS})
  for ch in ${CHIPS}; do
  for system in bvch shb vms; do
  llll=$SNP_DIR/dataWide${ch}/${system}/${idanimal}.lnk
      if test -s  ${llll}; then
        filelinked=$(ls -l ${llll} | awk '{print $NF}')
        echo ${llll} is unlinked from ${filelinked}
        unlink ${llll}
        echo ${idanimal} ${ch} >> ${HIS_DIR}/ReplacedAnimals.${run}.txt
      fi
  done
  done
  fi
  fi
done
done

sort -T ${SRT_DIR} -T ${SRT_DIR} -u ${HIS_DIR}/ReplacedAnimals.${run}.txt -o ${HIS_DIR}/ReplacedAnimals.${run}.txt    
cd ${lokal}
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

