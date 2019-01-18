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

#unabhaengig von markermap und genotypen
##############
#pedigree.file
if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
else
breed=${1}
    if [ $1 == "BSW" ] ; then
	rasse=bv
	d1=$(echo ${DatPEDIbvch})
    elif [ $1 == "HOL" ]; then
	rasse=rh
	d1=$(echo ${DatPEDIshb})
    elif [ $1 == "VMS" ]; then
        rasse=vms
        d1=$(echo ${DatPEDIvms})
    else
	echo ooops unbekannte rasse
	exit 1
    fi
    
    (echo "ID Sire Dam Sex";
    awk '{ print $1,$2,$3,substr($0,44,1)}' /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${d1}.txt ) > $FIM_DIR/${breed}Fimpute.ped
	


fi
echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

