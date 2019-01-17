#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################

if test -s $WRK_DIR/SingleSelectedSNPs.txt;
cat $WRK_DIR/SingleSelectedSNPs.txt |\
      while read sssnp; do
      for breed in BSW HOL VMS; do
      if test -s $WRK_DIR/${breed}.${sssnp}.lst; then
      rm $WRK_DIR/${breed}.${sssnp}.lst
      fi
      done
      done
fi

echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
