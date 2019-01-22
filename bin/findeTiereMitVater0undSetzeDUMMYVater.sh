#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################



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
	DUMMY1=$(echo ${lastANIMAL} | awk '{print $1+1}')
       
	
	(awk -v d1=${DUMMY1} '{if ($2 == 0) print $1,d1,$3,$4; else print $1,$2,$3,$4}' $FIM_DIR/${breed}Fimpute.ped ;
	    echo $DUMMY1 0 0 M) > $FIM_DIR/DUMMYsire${breed}Fimpute.ped
  
#setzte DUMMY Typsierung ins Genotypenfile
	nGENOS=$(awk '{if($2 == 1) print $3}' $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno | head -1 | wc -c | awk '{print $1-1}')
	genoSTRING=$(for i in $(seq 1 1 ${nGENOS} ); do echo 0; done | tr '\n' ' ' | sed 's/ //g')
	(cat $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno;
	echo "$DUMMY1 1 ${genoSTRING}") > $FIM_DIR/DUMMYsire${breed}BTAwholeGenome_FImpute.geno

	echo $DUMMY1 > $WORK_DIR/DUMMYsire.${breed}

fi



echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
