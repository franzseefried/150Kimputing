#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "



##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit


if [ -z $1 ]; then
    echo "brauche den Code fuer Start oder Ende"
    exit 1
fi

if [ $1 != "START" ] && [ $1 != "ENDE" ]; then
    echo "Code fuer Start oder Ende ist falsch, START / ENDE sind erlaubt"
    exit 1
fi

ort=$(uname -a | awk '{print $1}' )
if [ ${ort} == "Darwin" ]; then
    echo "change entweder zu eiger, titlis, beverin oder castor"
    exit 1
elif [ ${ort} == "Linux" ]; then
  maschine=$(uname -a | awk '{print $2}'  | cut -d'.' -f1)
  if [ ${maschine} == "titlis" ]; then
    linkaufloesung="/qualstore03"
  elif [ ${maschine} == "beverin" ]; then
    linkaufloesung="/qualstore03"
  elif [ ${maschine} == "castor" ]; then
    linkaufloesung="/qualstorzws01"
  elif [ ${maschine} == "eiger" ]; then
    linkaufloesung="/qualstorzws01"
  else
    echo "unknown server"
    exit 1
  fi
else
  echo "oops komisches Betriebssystem ich stoppe"
  exit 1
fi


for i in ${linkaufloesung}/data_zws ${linkaufloesung}/data_archiv ${linkaufloesung}/data_tmp; do
df ${i} 
done > ${TMP_DIR}/df.${1}.Imputation.${run}.log


if [ $1 == "ENDE" ]; then
echo "compare df from START and ENDE"
for i in ${linkaufloesung}/data_zws ${linkaufloesung}/data_archiv ${linkaufloesung}/data_tmp; do
dfSTART=$(awk -v f=${i} '{if($0 ~ f) print $4}'  ${TMP_DIR}/df.START.Imputation.${run}.log)
dfENDE=$(awk -v f=${i} '{if($0 ~ f) print $4}'  ${TMP_DIR}/df.ENDE.Imputation.${run}.log)
dfNEEDED=$(echo ${dfSTART} ${dfENDE} | awk '{print $1-$2}')
echo $dfNEEDED ${i}
done > ${DIFR_DIR}/dfmonitoring.RequiredDF.${run}.${oldrun}.txt
fi


errorFLAG=0
if [ $1 == "START" ]; then
echo "check if enough diskspace is available and calculate with 10 percent overhead"
for i in /qualstore03/data_zws /qualstore03/data_archiv /qualstore03/data_tmp; do
dfSTART=$(awk -v f=${i} '{if($0 ~ f) print $4}'  ${TMP_DIR}/df.START.Imputation.${run}.log | awk '{printf "%.0f\n", $1}')
if [ -z ${dfSTART} ] ;then
ii=$(echo $i | sed "s/qualstore03/qualstorzws01/g")
dfSTART=$(awk -v f=${ii} '{if($0 ~ f) print $4}' ${TMP_DIR}/df.START.Imputation.${run}.log | awk '{printf "%.0f\n", $1}' )
fi
#reserve von 20%
dfNEEDED=$(awk -v f=${i} '{if($0 ~ f) print $1*1.20}' ${DIFR_DIR}/dfmonitoring.RequiredDF.${oldrun}.${old2run}.txt | awk '{printf "%.0f\n", $1}' )
if [ -z ${dfNEEDED} ] ;then
ii=$(echo $i | sed "s/qualstore03/qualstorzws01/g")
dfNEEDED=$(awk -v f=${ii} '{if($0 ~ f) print $1*1.20}' ${DIFR_DIR}/dfmonitoring.RequiredDF.${oldrun}.${old2run}.txt | awk '{printf "%.0f\n", $1}' )
fi
#echo "$dfSTART ; $dfNEEDED"
if [ ${dfSTART} -lt ${dfNEEDED} ]; then
echo "diskspace available on ${i}: ${dfSTART}"
echo "diskspace needed    on ${i}: ${dfNEEDED}"
$BIN_DIR/sendMissingDF.Mail.sh ${i} ${dfSTART} ${dfNEEDED}
errorFLAG=1
fi
done
fi

#if [ ${errorFLAG} == 1 ]; then
#exit 1
#fi



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
