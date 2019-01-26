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

if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS' "
    exit 1
fi
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

#snpselektion via MAF und CLRT and HWE
$FRG_DIR/plink --bfile $TMP_DIR/${breed}merged_ --missing-genotype 0 --nonfounders --cow --noweb --geno 0.01 --maf 0.10 --hwe 0.00001 --recode --out $TMP_DIR/${breed}routine_GPsearch
awk '{print $2,"B"}' $TMP_DIR/${breed}routine_GPsearch.map > $TMP_DIR/${breed}routine_GPsearch.force.Bcount
$FRG_DIR/plink --bfile $TMP_DIR/${breed}merged_ --missing-genotype 0 --nonfounders --cow --noweb --geno 0.01 --maf 0.10 --hwe 0.00001  --recodeA --reference-allele $TMP_DIR/${breed}routine_GPsearch.force.Bcount --out $WORK_DIR/${breed}routine_GPsearch
wc -l $WORK_DIR/${breed}routine_GPsearch.raw


############################################################
echo " "
echo "Baue Genotypenfile jetzt fuer ${1}"
(echo "ID Chip Call..." ;
sed 's/ /#/1' $WORK_DIR/${breed}routine_GPsearch.raw | sed -n '2,$p' | sed 's/ /#/1' | sed 's/ /#/4' | cut -d'#' -f2,4 | sed 's/ //g' | sed 's/NA/5/g' | tr '#' ' ' | awk '{print $1,"1",$2}') > $FIM_DIR/${breed}.GPsearch_FImpute.geno
echo "Verteilung Chip Genotypenfile:"
awk '{if(NR > 1) print $2}' $FIM_DIR/${breed}.GPsearch_FImpute.geno | sort -T ${SRT_DIR} | uniq -c | awk '{print $1,$2}' | sort -T ${SRT_DIR} -t' ' -k2,2
echo " "
#############################################################
echo "Baue Markerfile jetzt fuer ${1}"
(echo "SNP_ID Chr Pos Chip1" ;
join -t' ' -o'1.1 2.1 2.4 1.2' -e'#' -a1 -1 1 -2 2 <(head -1 $WORK_DIR/${breed}routine_GPsearch.raw | cut -d' ' -f7- | tr ' ' '\n' | cat -n | awk '{print $2,$1}' | sed 's/_B / /g' | sort -T ${SRT_DIR} -t' ' -k1,1) <(awk '{print $1,$2,$3,$4}' $TMP_DIR/${breed}routine_GPsearch.map | sort -T ${SRT_DIR} -t' ' -k2,2) | sort -T ${SRT_DIR} -t' ' -k4,4n) > $FIM_DIR/${breed}.GPsearch_FImpute.snpinfo
wc -l $FIM_DIR/${breed}.GPsearch_FImpute.snpinfo
echo " "
############################################################
echo "Baue Pedigree jetzt fuer ${1}"
(echo "ID Sire Dam Sex";
awk '{ print $1,$2,$3,substr($0,44,1)}' /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${d1}.txt ) > $FIM_DIR/${breed}.GPsearch_Fimpute.ped



rm -f $TMP_DIR/${breed}routine_GPsearch*



echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

