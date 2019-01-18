#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
#set -o errexit

if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
elif [ ${1} == "BSW" ] || [ ${1} == "HOL" ] || [ ${1} == "VMS" ]; then
#set -o nounset
  breed=${1}
  echo "jetzt Typisierungsstatus mit letzter Imputation vergleichen"
  sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 $WRK_DIR/${breed}Typisierungsstatus${run}.txt    > $TMP_DIR/${breed}Typisierungsstatuscurrent.srt
  sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 $WRK_DIR/${breed}Typisierungsstatus${oldrun}.txt > $TMP_DIR/${breed}Typisierungsstatusprevious.srt
 	  
#  echo "previous LD Tiere now 50K"
  join -t' ' -o'1.1 1.2 2.2' -1 1 -2 1 $TMP_DIR/${breed}Typisierungsstatusprevious.srt $TMP_DIR/${breed}Typisierungsstatuscurrent.srt |\
    awk '{if($2 == "LD" && $3 == "DB") print }' > $RES_DIR/${breed}.LDin${oldrun}.ABER.50Kin${run}.txt	  
  if test -s $RES_DIR/${breed}.LDin${oldrun}.ABER.50Kin${run}.txt; then
    echo " "
    echo "SNP-UPgraded Samples:"
    wc -l $RES_DIR/${breed}.LDin${oldrun}.ABER.50Kin${run}.txt
  fi    
  join -t' ' -o'1.1 1.2 2.2' -1 1 -2 1 $TMP_DIR/${breed}Typisierungsstatusprevious.srt $TMP_DIR/${breed}Typisierungsstatuscurrent.srt |\
    awk '{if($2 == "DB" && $3 == "LD") print }' > $RES_DIR/${breed}.50Kin${oldrun}.ABER.LDin${run}.txt
  if test -s $RES_DIR/${breed}.50Kin${oldrun}.ABER.LDin${run}.txt; then
    echo " "
    echo "SNP-DOWNgraded Samples:"
    wc -l $RES_DIR/${breed}.50Kin${oldrun}.ABER.LDin${run}.txt
  fi     
  join -t' ' -o'1.1 1.2' -v1 -1 1 -2 1 $TMP_DIR/${breed}Typisierungsstatusprevious.srt $TMP_DIR/${breed}Typisierungsstatuscurrent.srt |\
    awk '{print  $1,$2}' > $RES_DIR/${breed}.lostANIMALS.in${run}_imVglmit${oldrun}.txt	      
  if test -s $RES_DIR/${breed}.lostANIMALS.in${run}_imVglmit${oldrun}.txt ; then
	  echo " "
          echo "ACHTUNG NICHT mehr alle ${breed}-Tiere im Vergleich zum letzten ImputationsRun vorhanden."
	  echo echo "SNP-LOST Samples:"
          wc -l  $RES_DIR/${breed}.lostANIMALS.in${run}_imVglmit${oldrun}.txt
          echo " "
          echo "Diese sind mit dem alten Chiptyp im file $RES_DIR/${breed}.lostANIMALS.in${run}_imVglmit${oldrun}.txt enthalten"
	  echo "Generell sollten alle Tiere des previous Runs im aktuellen Run auch drin sein"
	  echo "ausser es wurden einzelne Tiere mutiert, bzw. deren SNP gelöscht"
	  echo "checke die Tiere bevor du weiter machst"
  fi
  join -t' ' -o'2.1 2.2' -v2 -1 1 -2 1 $TMP_DIR/${breed}Typisierungsstatusprevious.srt $TMP_DIR/${breed}Typisierungsstatuscurrent.srt |\
    awk '{print  $1,$2}' > $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt    
  if test -s $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt; then
    echo " "
    echo "SNP-new Samples:"
    wc -l $RES_DIR/${breed}.newANIMALS.in${run}_imVglmit${oldrun}.txt
  fi
  rm -f $TMP_DIR/${breed}Typisierungsstatuscurrent.srt
  rm -f $TMP_DIR/${breed}Typisierungsstatusprevious.srt
else
    echo "Kenne die angegebene Rasse ${1} nicht"
fi


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}


