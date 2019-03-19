#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
#set -o errexit
START_DIR=$(pwd)


if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
fi

set -o nounset
breed=${1}


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
TIERLIScheck () {
existshot=N
existresult=Y
while [ ${existshot} != ${existresult} ]; do
if test -s ${1}  ; then
RIGHT_NOW=$(date +"%x %r %Z")
existshot=Y
echo $RIGHT_NOW
fi
done

echo "file to check  ${1}  exists ${RIGHT_NOW}, check if it is ready"
shotcheck=same
shotresult=unknown
current=$(date +%s)
while [ ${shotcheck} != ${shotresult} ]; do
 lmod=$(stat -c %Y ${1} )
 echo $lmod	
 RIGHT_NOW=$(date +"%x %r %Z")
 #echo $current $lmod
 if [ ${lmod} > 240 ]; then
    shotresult=same
    echo "${1} is ready now ${RIGHT_NOW}"
 fi
done

}
##########################

#get Info about SNP from Reftab
getColmnNrSemicl ExtractGenotypesFromChipData ${REFTAB_SiTeAr} ; colEXG=$colNr_
getColmnNrSemicl CodeResultfile ${REFTAB_SiTeAr} ; colCSGI=$colNr_
getColmnNrSemicl BTA ${REFTAB_SiTeAr} ; colGSB=$colNr_
getColmnNrSemicl PredictionAlgorhithm ${REFTAB_SiTeAr} ; colABAASGI=$colNr_
getColmnNrSemicl IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBRD=$colNr_


declare -a algis=$(awk -v a=${colABAASGI} -v b=${colCSGI} -v c=${colIMPBRD} -v d=${breed} 'BEGIN{FS=";"}{if($c ~ d) print $a}' ${REFTAB_SiTeAr} | sort -u | grep \[A-Z\] |tr '\n' ' ')
if [ ${#algis[@]} -eq 0 ]; then
echo "PredictionAlgortithm array is empty:  ${#algis[@]}"
exit 1
fi


sleep 10


existshot=N
existresult=Y
while [ ${existshot} != ${existresult} ]; do
ls -l $TMP_DIR/${breed}.[A-Z]*.selected > /dev/null 2>&1
if [ "$?" = "0" ]; then
RIGHT_NOW=$(date +"%x %r %Z")
existshot=Y
echo $RIGHT_NOW
fi
done


#define list of expected files
halist=$(cat $TMP_DIR/${breed}.[A-Z]*.selected | tr '\n' ' ')
#echo $halist
for iha in ${halist[@]}; do
echo ${iha};
existshot=N
existresult=Y
while [ ${existshot} != ${existresult} ]; do
ls -l $RES_DIR/RUN${run}${breed}.${iha}.*[A-Z] > /dev/null 2>&1
if [ "$?" = "0" ]; then
filetocheck=$(ls $RES_DIR/RUN${run}${breed}.${iha}.*[A-Z])
RIGHT_NOW=$(date +"%x %r %Z")
existshot=Y
fi
done
TIERLIScheck ${filetocheck}
done




echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
