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
fi
if [ -z $2 ]; then
    echo "brauche den Parameter 2: den filenamen den ich pruefen soll"
    exit 1 
fi

set -o nounset
breed=${1}
fileTOcheck=${2}



sleep 60

#Definition der Funktion
###########################################
Tierlischeck () {

existshot=N
existresult=Y
while [ ${existshot} != ${existresult} ]; do
if test -s ${fileTOcheck}  ; then
RIGHT_NOW=$(date +"%x %r %Z")
existshot=Y
fi
done


echo "Tierlis ${breed} file exists ${RIGHT_NOW}, check if it is ready"
shotcheck=same
shotresult=unknown
current=$(date +%s)
while [ ${shotcheck} != ${shotresult} ]; do
 lmod=$(stat -c %Y ${fileTOcheck} )
 RIGHT_NOW=$(date +"%x %r %Z")
 #echo $current $lmod
 if [ ${lmod} > 360 ]; then
    shotresult=same
    echo "${fileTOcheck} is ready now ${RIGHT_NOW}"
 fi
done

}
#############################################
#aufruf der Funktion
Tierlischeck




echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
