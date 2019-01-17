#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
export lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit


#echo $upf $putfolder

cd ${PEDI_DIR}/data/shzv/


echo "files to be downloaded:"
echo ${pedigreeSHZV}
echo ${blutfileSHZV}
echo " "
echo "connecting ftp now"

HOST='ftp.elvadata.ch'
USER='qualitas'
PASSWD='DPiv35$!'
#datei='USAM000000022235_D.pdf'
#echo $datei
ftp -n $HOST <<end_skript
quote USER $USER
quote PASS $PASSWD
cd ImputierungHolstein
binary
dir
get ${pedigreeSHZV}
get ${blutfileSHZV}
quit
end_skript
echo " "
pwd
ls -trl ${blutfileSHZV}
ls -trl ${pedigreeSHZV}

echo " "
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}
