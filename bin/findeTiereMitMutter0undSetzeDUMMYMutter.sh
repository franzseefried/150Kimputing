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
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
else
   set -o errexit
   set -o nounset
   
   breed=${1}
#setzte DUMMY Vaeter und Mutter ins Pedigree
	lastANIMAL=$((awk '{print $1 }'  $FIM_DIR/${breed}Fimpute.ped | sort -T ${SRT_DIR} -u ;
	    awk '{print $2 }'  $FIM_DIR/${breed}Fimpute.ped | sort -T ${SRT_DIR} -u ;
	    awk '{print $3 }'  $FIM_DIR/${breed}Fimpute.ped | sort -T ${SRT_DIR} -u ;) | sort -T ${SRT_DIR} -n | tail -1)

	DUMMY2=$(echo ${lastANIMAL} | awk '{print $1+2}' )
        DUMMY1=$(echo ${DUMMY2} | awk '{print $1-1}')	
	(awk -v d2=${DUMMY2} '{if ($3 == 0) print $1,$2,d2,$4; else print $1,$2,$3,$4}' $FIM_DIR/${breed}Fimpute.ped;
	    echo $DUMMY2 0 0 F;) > $FIM_DIR/DUMMYdam${breed}Fimpute.ped
  
#setzte DUMMY Typsierung ins Genotypenfile
	nGENOS=$(awk '{if($2 == 1) print $3}' $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno | head -1 | wc -c | awk '{print $1-1}')
	genoSTRING=$(for i in $(seq 1 1 ${nGENOS} ); do echo 0; done | tr '\n' ' ' | sed 's/ //g')
	(cat $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno;
	    echo $DUMMY2 1 ${genoSTRING};) > $FIM_DIR/DUMMYdam${breed}BTAwholeGenome_FImpute.geno

	echo $DUMMY1 $DUMMY2 > $WORK_DIR/DUMMYdam.${breed}

fi


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
