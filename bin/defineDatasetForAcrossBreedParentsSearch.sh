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
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'ALL'"
    exit 1
fi
breed=${1}
BTA=wholeGenome
##################################################
#use only common LD snps
echo "SNP_ID Chr Pos Chip1" > $FIM_DIR/${breed}BTA${BTA}_FImpute.snpinfo
for pop in BSW VMS HOL;do
awk '{if(NR > 1 && $5 != 0) print $1,$2,$3}' $FIM_DIR/${pop}BTA${BTA}_FImpute.snpinfo
done | sort -T $SRT_DIR |uniq -c | awk '{if($1 == 2) print $2,$3,$4}' | sort -t' ' -k2,2n -k3,3n | awk '{print $0,NR}' >> $FIM_DIR/${breed}BTA${BTA}_FImpute.snpinfo
awk '{if(NR > 1) print $1}' $FIM_DIR/${breed}BTA${BTA}_FImpute.snpinfo > $TMP_DIR/${breed}BTA${BTA}_ACRPDC.txt
awk '{if(NR > 1) print $1,"B"}' $FIM_DIR/${breed}BTA${BTA}_FImpute.snpinfo > $TMP_DIR/${breed}BTA${BTA}_ACRPDC.force.Bcount
#pedigree and IDs
for pop in BSW VMS HOL; do
awk -v pp=${pop} '{if(NR > 1) print "1",$1,"1",pp$1}' $FIM_DIR/${pop}Fimpute.ped > $TMP_DIR/${pop}.umcd.tble
done
echo "ID Sire Dam Sex" > $FIM_DIR/${breed}Fimpute.ped
for pop in BSW VMS HOL;do
awk -v pp=${pop} '{if(NR > 1) print pp$1,pp$2,pp$3,$4}' $FIM_DIR/${pop}Fimpute.ped_siredamkorrigiert_NGPsiredamkorrigiert | sed "s/${pop}0 /0 /g"
done >> $FIM_DIR/${breed}Fimpute.ped


for pop in BSW VMS HOL; do 
awk -v pp=${pop} '{if(NR > 1) print pp$1,pp$2,pp$3,$4,$5,$6,$7}' $WORK_DIR/ped_umcodierung.txt.${pop}.updated | sed "s/${pop}0 /0 /g"
done > $WORK_DIR/ped_umcodierung.txt.${breed}


for pop in BSW VMS HOL; do
echo "update ids"

#ausschreiben in betrennte files
$FRG_DIR/plink --bfile $TMP_DIR/${pop}merged_ --missing-genotype 0 --nonfounders --cow --noweb --update-ids $TMP_DIR/${pop}.umcd.tble --extract $TMP_DIR/${breed}BTA${BTA}_ACRPDC.txt --make-bed  --out $TMP_DIR/${pop}_ACRPDC

done

#mergen genotypen
$FRG_DIR/plink --bfile $TMP_DIR/BSW_ACRPDC --bmerge $TMP_DIR/VMS_ACRPDC --nonfounders --cow --noweb --make-bed --out $TMP_DIR/_ACRPDC
#$FRG_DIR/plink --bfile $TMP_DIR/_ACRPDC --nonfounders --cow --noweb --recodeA --reference-allele $TMP_DIR/${breed}BTA${BTA}_ACRPDC.force.Bcount --out $TMP_DIR/${breed}_ACRPDC
#wenn ohne HOL
$FRG_DIR/plink --bfile $TMP_DIR/_ACRPDC --bmerge $TMP_DIR/HOL_ACRPDC --nonfounders --cow --noweb --recodeA --reference-allele $TMP_DIR/${breed}BTA${BTA}_ACRPDC.force.Bcount  $TMP_DIR/${breed}_ACRPDC



echo " "
echo " "
echo "Baue Genotypenfile jetzt fuer ${1}"
(echo "ID Chip Call..." ;
sed 's/ /#/1' $TMP_DIR/${breed}_ACRPDC.raw | sed -n '2,$p' | sed 's/ /#/1' | sed 's/ /#/4' | cut -d'#' -f2,4 | sed 's/ //g' | sed 's/NA/5/g' | tr '#' ' ' | awk '{print $1,"1",$2}';) > $FIM_DIR/${breed}BTA${BTA}_FImpute.geno

echo "Verteilung Chip Genotypenfile:"
awk '{if(NR > 1) print $2}' $FIM_DIR/${breed}BTA${BTA}_FImpute.geno | sort -T ${SRT_DIR} | uniq -c | awk '{print $1,$2}' | sort -T ${SRT_DIR} -t' ' -k2,2





echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
