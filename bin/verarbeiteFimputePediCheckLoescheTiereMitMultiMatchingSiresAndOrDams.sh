#!/bin/bash
RIGHT_NOW=$(date )
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

for i in $TMP_DIR/${breed}.NGPCMULTImatchingsire.animals $TMP_DIR/${breed}.NGPCMULTImatchingdam.animals $TMP_DIR/${breed}.MULTImatchingdam.animals $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_undOHNEsurrogateDAM.srt $TMP_DIR/${breed}.MULTImatchingsire.animals; do
if ! test -s ${i}; then touch ${i}; fi
done


(cat $TMP_DIR/${breed}.TiereMitVATERPROBLEM_undOHNEsurrogateSIRE.srt;
 cat $TMP_DIR/${breed}.MULTImatchingsire.animals;
 cat $TMP_DIR/${breed}.TiereMitMUTTERPROBLEM_undOHNEsurrogateDAM.srt; 
 cat $TMP_DIR/${breed}.MULTImatchingdam.animals;
 cat $TMP_DIR/${breed}.NGPCMULTImatchingsire.animals; 
 cat $TMP_DIR/${breed}.NGPCMULTImatchingdam.animals) | sort -T ${SRT_DIR} -u > $TMP_DIR/${breed}.TODELETEduePEDIGREEissues.txt

            
    echo loesche Tiere ohne Vater/Mutter-Match, sowie Tiere mit MultiMatch Vater/Mutter aus dem Genotypenfile
    mv $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno $FIM_DIR/${breed}BTAwholeGenome_FImpute.genoORG

	(head -1 $FIM_DIR/${breed}BTAwholeGenome_FImpute.genoORG;
	awk 'BEGIN{FS=" ";OFS=" "}{ \
            if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));NDel[$1]=$2;}} \
            else {sub("\015$","",$(NF));DLT="0";DLT=NDel[$1]; \
            if   (DLT == "") {print $0}}}' $TMP_DIR/${breed}.TODELETEduePEDIGREEissues.txt $FIM_DIR/${breed}BTAwholeGenome_FImpute.genoORG | grep -v "ID Chip") > $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno
    rm -f $FIM_DIR/${breed}BTAwholeGenome_FImpute.genoORG
fi


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
