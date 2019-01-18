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
else
for breed in ${1}; do
    BTA=wholeGenome
    echo "find animals"
    awk '{if($2 == "DB") print $1,$2}' $WORK_DIR/${breed}Typisierungsstatus${run}.txt | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}Typisierungsstatus${run}.srtFIFTYK
    awk '{if($2 != "DB") print $1,$2}' $WORK_DIR/${breed}Typisierungsstatus${run}.txt | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}Typisierungsstatus${run}.srtLD
    sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed} | join -t' ' -o'1.1' -1 5 -2 1 - $TMP_DIR/${breed}Typisierungsstatus${run}.srtFIFTYK | awk '{print "1",$1}' > $TMP_DIR/${breed}.FIFTYKanimals.out
    sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed} | join -t' ' -o'1.1' -1 5 -2 1 - $TMP_DIR/${breed}Typisierungsstatus${run}.srtLD | awk '{print "1",$1}' > $TMP_DIR/${breed}.LDanimals.out


    #find SNPs"
    awk '{if($4 != 0)print $1}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt > $TMP_DIR/${breed}.HDsnps.keep
    awk '{if($5 != 0)print $1}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt > $TMP_DIR/${breed}.LDsnps.keep

    #ausschreiben in betrennte files
    $FRG_DIR/plink --bfile $TMP_DIR/${breed}merged_ --missing-genotype 0 --nonfounders --cow --noweb --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --keep $TMP_DIR/${breed}.FIFTYKanimals.out --extract $TMP_DIR/${breed}.HDsnps.keep --out $WORK_DIR/${breed}FIFTYK_routine_BTAwholeGenome
    $FRG_DIR/plink --bfile $TMP_DIR/${breed}merged_ --missing-genotype 0 --nonfounders --cow --noweb --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --keep $TMP_DIR/${breed}.LDanimals.out     --extract $TMP_DIR/${breed}.LDsnps.keep --out $WORK_DIR/${breed}LD_routine_BTAwholeGenome

    echo " "
    echo " "
    echo "Baue Genotypenfile jetzt fuer ${1}"
    (echo "ID Chip Call..." ;
	sed 's/ /#/1' $WORK_DIR/${breed}FIFTYK_routine_BTAwholeGenome.raw | sed -n '2,$p' | sed 's/ /#/1' | sed 's/ /#/4' | cut -d'#' -f2,4 | sed 's/ //g' | sed 's/NA/5/g' | tr '#' ' ' | awk '{print $1,"1",$2}';
	sed 's/ /#/1' $WORK_DIR/${breed}LD_routine_BTAwholeGenome.raw | sed -n '2,$p' | sed 's/ /#/1' | sed 's/ /#/4' | cut -d'#' -f2,4 | sed 's/ //g' | sed 's/NA/5/g' | tr '#' ' ' | awk '{print $1,"2",$2}';) > $FIM_DIR/${breed}BTA${BTA}_FImpute.geno
    
    echo "Verteilung Chip Genotypenfile:"
    sed -n '2,$p' $FIM_DIR/${breed}BTA${BTA}_FImpute.geno | awk '{print $2}' | sort -T ${SRT_DIR} | uniq -c | awk '{print $1,$2}' | sort -T ${SRT_DIR} -t' ' -k2,2

   rm -f $TMP_DIR/${breed}Typisierungsstatus${run}.srtFIFTYK
   rm -f $TMP_DIR/${breed}Typisierungsstatus${run}.srtLD
   rm -f $TMP_DIR/${breed}.LDanimals.out
   rm -f $TMP_DIR/${breed}.HDsnps.keep
   rm -f $TMP_DIR/${breed}.LDsnps.keep

done
fi

echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

