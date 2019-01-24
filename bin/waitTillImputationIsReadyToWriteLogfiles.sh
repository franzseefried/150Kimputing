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
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
else 

set -o nounset
breed=${1}



sleep 10
if [ ${breed} == "BSW" ] || [ ${breed} == "HOL" ] || [ ${breed} == "VMS" ]; then
arayfile="$RES_DIR/${breed}.GenomicFcoefficient.${run}.txt $RES_DIR/${breed}.PedigreeFcoefficient.${run}.txt $RES_DIR/${breed}.SNPtwins.${run}.txt $ZOMLD_DIR/${breed}_suspiciousVVs.${run}.csv $ZOMLD_DIR/${breed}_suspiciousMVs.${run}.csv $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis"
fi


for filetocheck in $(echo ${arayfile}); do
TIERLIScheck () {

existshot=N
existresult=Y
while [ ${existshot} != ${existresult} ]; do
if test -s ${filetocheck}  ; then
RIGHT_NOW=$(date +"%x %r %Z")
existshot=Y
fi
done


echo "file to check  ${filetocheck}  exists ${RIGHT_NOW}, check if it is ready"
shotcheck=same
shotresult=unknown
current=$(date +%s)
while [ ${shotcheck} != ${shotresult} ]; do
 lmod=$(stat -c %Y ${filetocheck} )
 RIGHT_NOW=$(date +"%x %r %Z")
 #echo $current $lmod
 if [ ${lmod} > 360 ]; then
    shotresult=same
    echo "${filetocheck} is ready now ${RIGHT_NOW}"
 fi
done

}
TIERLIScheck
done
fi



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
