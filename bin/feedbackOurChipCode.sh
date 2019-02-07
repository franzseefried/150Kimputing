#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
#echo $RIGHT_NOW Start ${SCRIPT} 
#echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit

#define function to chek when parallel jobs are ready

PRLLRUNcheck () {
#echo ${1};
existshot=N
existresult=Y
while [ ${existshot} != ${existresult} ]; do
if test -s ${1}  ; then
RIGHT_NOW=$(date +"%x %r %Z")
existshot=Y
fi
done


echo "file to check  ${1}  exists ${RIGHT_NOW}, check if it is ready"
shotcheck=same
shotresult=unknown
current=$(date +%s)
while [ ${shotcheck} != ${shotresult} ]; do
 lmod=$(stat -c %Y ${1} )
 RIGHT_NOW=$(date +"%x %r %Z")
 #echo $current $lmod
 if [ ${lmod} > 120 ]; then
    shotresult=same
    echo "${1} is ready now ${RIGHT_NOW}"
 fi
done

}

##############################################################


#Zielmap enthaelt schon nur noch die LD-SNP die auch auf dem HD chip drauf sind
#Programm schreibt neue Map für sas Imputing, d.h. die map aus writeNewAimMap.sh wird hier uerberschrieben
#2 Chips hier
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

#get Info about SNP from Reftab
getColmnNrSemicl IntergenomicsCode ${REFTAB_CHIPS} ; colITGX=$colNr_
getColmnNrSemicl QuagCode ${REFTAB_CHIPS} ; colQUG=$colNr_
#echo $colITGX $colQUG
HDchipZiel=$(awk -v cc=${colQUG} -v dd=${colITGX} -v nc=${NewChip1} 'BEGIN{FS=";"}{if( $dd == nc ) print $cc }' ${REFTAB_CHIPS})
echo $HDchipZiel








#echo " "
#RIGHT_END=$(date)
#echo $RIGHT_END Ende ${SCRIPT}
