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



ls -trl ${LAB_DIR}/*
echo " "
echo "loeschen der leeren files now"
for file in $( find ${LAB_DIR}/*) ; do
    if [ ! -s ${file} ] ; then
       rm -f  ${file};
    fi;
done
echo " "
ls -trl ${LAB_DIR}/*



cd $LAB_DIR
for labfile in $(ls *toWorkWith) ; do
#for labfile in $(ls Qualitas*toWorkWith) ; do
#
  if [ ! -s ${labfile} ] ; then
	rm -f ${labfile}
  else
     for rasse in BSW HOL VMS OTHER; do
       cat $BIN_DIR/awk_trenneGenotypen_nachRassen | sed "s/XXXXXXX/${rasse}/g" > $BIN_DIR/awk_trenneGenotypen_nachRassen.doit
       chmod 777 $BIN_DIR/awk_trenneGenotypen_nachRassen.doit
       $BIN_DIR/awk_trenneGenotypen_nachRassen.doit  $TMP_DIR/crossref.race $LAB_DIR/${labfile} > $LAB_DIR/${rasse}-${labfile}
     done
     if test -s $LAB_DIR/OTHER-${labfile} ; then
        echo " "
        echo "ooops ich habe Proben die weder BSW noch HOL sind, bitte Spalte AC in $WORK_DIR/${crossreffile} prüfen"
        echo "${labfile} wird verschoben ins $LOG_DIR "
        mv $LAB_DIR/OTHER-${labfile} $LOG_DIR/.
     else
        rm -f $LAB_DIR/${labfile}
     fi
  fi
done
rm -f ${BIN_DIR}/awk_trenneGenotypen_nachRassen.doit


cd ${lokal}
echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

