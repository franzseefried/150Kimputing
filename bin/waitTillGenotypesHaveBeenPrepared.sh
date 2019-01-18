#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit
set -o nounset
set -o pipefail
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



set -o nounset
breed=${1}


#define breed loop
colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ImputationDensityLD150K | awk '{print $1}')
colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')
DENSITIES=$(awk -v cc=${colDENSITY} 'BEGIN{FS=";"}{ if(NR > 1) print $cc }' ${REFTAB_CHIPS} | sort -T ${SRT_DIR} -T ${SRT_DIR} -u | awk '{if($1 != "") print}')


#echo ${DENSITIES}

#teil Plink
Plinkcheck () {

for dens in ${DENSITIES} ; do
existshot=N
existresult=Y
while [ ${existshot} != ${existresult} ]; do
if test -s $TMP_DIR/${breed}${dens}.bed; then
existshot=Y
fi
done
done

echo "Plink binary files exist, check if they are ready"
for dens in ${DENSITIES} ; do
shotcheck=same
shotresult=unknown
current=$(date +%s)
while [ ${shotcheck} != ${shotresult} ]; do
 lmod=$(stat -c %Y $TMP_DIR/${breed}${dens}.bed)
 #echo $current $lmod
 if [ ${lmod} > 360 ]; then
    shotresult=same
    #shotresult=$(${BIN_DIR}/check2snapshotsOF1file.sh $TMP_DIR/${breed}${dens}.bed | awk '{print $3}')
    echo "$TMP_DIR/${breed}${dens}.bed is ready"
 fi
done
done
}

Plinkcheck



#check plink logfiles
$BIN_DIR/smallcheckPLINKlogfiles.sh ${breed}



echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

