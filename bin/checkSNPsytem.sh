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

if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL oder VMS "
    exit 1
elif [ $1 == 'BSW' ] || [ $1 == 'HOL' ]  || [ $1 == 'VMS' ] ; then
set -o nounset
    breed=$(echo "$1")

#test if current system is identical with previous system
ARR2=$(awk '{if(NR > 1)print $1}' $HIS_DIR/${breed}.RUN${oldrun}snp_info.txt | tr '\n' ' ' )
ARR3=$(awk '{if(NR > 1)print $1}' ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo |tr '\n' ' ' )
ARR1=$(awk '{if(NR > 1)print $1}' $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt |tr '\n' ' ' )
A=${ARR1[@]};
B=${ARR2[@]};
C=${ARR3[@]};
if [ "$A" == "$B" ] && [ "$A" == "$C" ] ; then
    echo "Current SNPsytem is identical with previous ones" ;
else
   if [ "$A" == "$B" ];then
      echo "oldrun $oldrun SNPsytem differs from $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt"
   fi
   if [ "$A" == "$C" ];then
     echo "current SNPsytem differs from $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt"
   fi
   exit 1
fi;

else
    echo "komischer breedcode :-("
    exit 1
fi

echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
