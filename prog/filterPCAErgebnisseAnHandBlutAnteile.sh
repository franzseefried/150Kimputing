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
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
elif [ -z $2 ]; then
    echo "brauche die Untergrenze von Blutanteil als Dezimalzahl, z.B. 0.75"
    exit 1
elif [ -z $3 ]; then
    echo "brauche die Obergrenze von Blutanteil als Dezimalzahl, z.B. 0.75"
    p=${2}
    exit 1
elif [ -z $4 ]; then
    echo "brauche den Chip: LD oder FIFTYK"
    exit 1
elif [ $1 == 'BSW' ] || [ $1 == 'HOL' ] ; then
    echo " "
    (head -1 $RES_DIR/${1}${4}.PCA.scores.txt | tr ';' ' ';
	cat  $RES_DIR/${1}${4}.PCA.scores.txt | tr ';' ' ' |\
	awk -v c1=${2} -v c2=${3} '{if($14 >= c1 && $14 <= c2) print $1,$3,$4,$13,$14}' | sort -T ${SRT_DIR} -t' ' -k2,2n -k3,3n )
else
    echo "was komisch :( please check"

fi


echo " "
RIGHT_NOW=$(date)
echo $RIGHT_NOW Ende ${SCRIPT}
