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
      sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/pdumdocdcdcd.srt.${breed}

    awk '{if(NR > 1) print $1,$1}' $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.inputanimals


    join -t' ' -o'2.5 1.2 2.2 2.3' -1 1 -2 1 $TMP_DIR/${breed}.inputanimals $TMP_DIR/pdumdocdcdcd.srt.${breed} |\
           sort -T ${SRT_DIR} -t' ' -k3,3 |\
           join -t' ' -o'1.1 1.2 1.3 2.2 1.4' -e'-' -a1 -1 3 -2 1 - $TMP_DIR/${breed}.inputanimals |\
           sort -T ${SRT_DIR} -t' ' -k5,5 |\
           join -t' ' -o'1.1 1.2 1.3 1.4 1.5 2.2' -e'-' -a1 -1 5 -2 1 - $TMP_DIR/${breed}.inputanimals |\
           sort -T ${SRT_DIR} -t' ' -k5,5 |\
           join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 2.2' -e'-' -a1 -1 5 -2 1 - $TMP_DIR/pdumdocdcdcd.srt.${breed} |\
           sort -T ${SRT_DIR} -t' ' -k7,7 |\
           join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 1.7 2.2' -e'-' -a1 -1 7 -2 1 -  $TMP_DIR/${breed}.inputanimals |\
           sort -T ${SRT_DIR} -t' ' -k3,3 |\
           join -t' ' -o'1.1 1.2 2.5 1.4 1.5 1.6 1.7 1.8' -e'-' -a1 -1 3 -2 1 -  $TMP_DIR/pdumdocdcdcd.srt.${breed} |\
           sort -T ${SRT_DIR} -t' ' -k5,5 |\
           join -t' ' -o'1.1 1.2 1.3 1.4 2.5 1.6 1.7 1.8' -e'-' -a1 -1 5 -2 1 -  $TMP_DIR/pdumdocdcdcd.srt.${breed} |\
           sort -T ${SRT_DIR} -t' ' -k7,7 |\
           join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 2.5 1.8' -e'-' -a1 -1 7 -2 1 -  $TMP_DIR/pdumdocdcdcd.srt.${breed} |\
           sort -T ${SRT_DIR} -t' ' -k1,1 |\
           join -t' ' -o'1.1 2.1 1.3 1.4 1.5 1.6 1.7 1.8' -e'-' -a1 -1 1 -2 5 -  <(sort -T ${SRT_DIR} -t' ' -k5,5 $TMP_DIR/pdumdocdcdcd.srt.${breed}) | sort -T ${SRT_DIR} -t' ' -k1,1 | awk '{if($4 == "-" && $3 != "-") print}' > $TMP_DIR/${breed}samplesWithNonGenotypedSire_${run}.txt  

#setzte DUMMY Vaeter und Mutter ins Pedigree
	lastANIMAL=$((awk '{print $1 }'  $FIM_DIR/${breed}Fimpute.ped_siredamkorrigiert | sort -T ${SRT_DIR} -u ;
	    awk '{print $2 }'  $FIM_DIR/${breed}Fimpute.ped_siredamkorrigiert | sort -T ${SRT_DIR} -u ;
	    awk '{print $3 }'  $FIM_DIR/${breed}Fimpute.ped_siredamkorrigiert | sort -T ${SRT_DIR} -u ;) | sort -T ${SRT_DIR} -n | tail -1)
	PHANTOM1=$(echo ${lastANIMAL} | awk '{print $1+1}')
       
	
	(awk -v p1=${PHANTOM1} 'BEGIN{FS=" ";OFS=" "}{ \
                                if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$2]=$2;}} \
                                else {sub("\015$","",$(NF));PCI="0";PCI=PC[$1]; \
                                if   (PCI == "") {print $0} \
                                else             {print $1,p1,$3,$4}}}' $TMP_DIR/${breed}samplesWithNonGenotypedSire_${run}.txt $FIM_DIR/${breed}Fimpute.ped_siredamkorrigiert ;
	    echo $PHANTOM1 0 0 M) > $FIM_DIR/PHANTOMsire${breed}Fimpute.ped

  
#setzte DUMMY Typsierung ins Genotypenfile
	nGENOS=$(awk '{if ($2 == 1) print $3}' $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno | head -1 | wc -c | awk '{print $1-1}')
	genoSTRING=$(for i in $(seq 1 1 ${nGENOS} ); do echo 0; done | tr '\n' ' ' | sed 's/ //g')
	(cat $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno;
	    echo $PHANTOM1 1 ${genoSTRING};) > $FIM_DIR/PHANTOMsire${breed}BTAwholeGenome_FImpute.geno

	echo $PHANTOM1 > $WORK_DIR/PHANTOMsire.${breed}

rm -f $TMP_DIR/pdumdocdcdcd.srt.${breed}
rm -f $TMP_DIR/pdumdocdcdcd.srt.${breed}
rm -f $TMP_DIR/${breed}.inputanimals
rm -f $TMP_DIR/${breed}samplesWithNonGenotypedSire_${run}.txt  
fi



echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
