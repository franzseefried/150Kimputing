#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL oder VMS"
    exit 1
elif [ -z $2 ]; then
    echo "brauche die Untergrenze von PC1 / also der x-Achse, z.B. -0.0006"
    exit 1
elif [ -z $3 ]; then
    echo "brauche die Obergrenze von PC1 / also der x-Achse, z.B. +0.0006"
    p=${2}
    exit 1
elif [ -z $4 ]; then
    echo "brauche die Untergrenze von PC2 / also der y-Achse, z.B. -0.0006"
    exit 1
elif [ -z $5 ]; then
    echo "brauche die Obergenze von PC2 / also der y-Achse, z.B. +0.0006"
    exit 1
elif [ -z $6 ]; then
    echo "brauche den Chip: LD oder HD"
    exit 1
elif [ $1 == 'BSW' ] || [ $1 == 'HOL' ]  || [ $1 == 'VMS' ]; then
    echo " "
    (head -1 $RES_DIR/${1}${6}.PCA.scores.txt | tr ';' ' ';
	cat  $RES_DIR/${1}${6}.PCA.scores.txt | tr ';' ' ' |\
	awk -v c1=${2} -v c2=${3} -v d1=${4} -v d2=${5} '{if($3 >= c1 && $3 <= c2 && $4 >= d1 && $4 <= d2) print $1,$3,$4,$13,$14}' )
else
    echo "was komisch :( please check"

fi


echo " "
RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}
