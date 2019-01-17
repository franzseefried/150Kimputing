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
elif [ ${1} == "BSW" ]; then
	echo $1 > /dev/null
elif [ ${1} == "HOL" ]; then
	echo $1 > /dev/null
elif [ ${1} == "VMS" ]; then
        echo $1 > /dev/null
else
	echo " $1 != BSW / HOL / VMS, ich stoppe"
	exit 1
fi
set -o nounset

#schliesse LD-SNPs aus die nicht auf dem 50K Chip sind 
#for rasse in BSW HOL VMS; do
for rasse in ${1} ; do
    sort -T ${SRT_DIR} -t' ' -k2,2 $WORK_DIR/${rasse}FIFTYK.map > $TMP_DIR/${rasse}hdmap.SRT
    sort -T ${SRT_DIR} -t' ' -k2,2 $WORK_DIR/${rasse}LD.map > $TMP_DIR/${rasse}ldmap.SRT
    join -t' ' -o'2.2' -1 2 -2 2 -v2 $TMP_DIR/${rasse}hdmap.SRT $TMP_DIR/${rasse}ldmap.SRT > $TMP_DIR/${rasse}LD.onlyLD.snps
    join -t' ' -o'2.1 2.2 2.3 2.4' -1 2 -2 2 $TMP_DIR/${rasse}hdmap.SRT $TMP_DIR/${rasse}ldmap.SRT > $TMP_DIR/${rasse}LD-FIFTYK.overlap.tmp
    sort -T ${SRT_DIR} -t' ' -k2,2 $TMP_DIR/${rasse}LD-FIFTYK.overlap.tmp > $TMP_DIR/${rasse}LD-FIFTYK.overlap.srt
    join -t' ' -o'2.2' -1 2 -2 2 $TMP_DIR/${rasse}ldmap.SRT  $TMP_DIR/${rasse}LD-FIFTYK.overlap.srt > $TMP_DIR/${rasse}LDgenrelMAP.SRT 

    echo "allelfrequenzen berechnen"
    $FIFK_DIR/bin/zusammenstellenFilemitBlutanteilenForGCTAGenRelMat.sh ${breed}
    err=$(echo $?)
    if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/zusammenstellenFilemitBlutanteilenForGCTAGenRelMat.sh ${breed}
        exit 1
    fi
    echo "----------------------------------------------------"
    if [ ${breed} == "BSW" ];then cutting=$(echo "2,3,4");fi
    if [ ${breed} == "HOL" ];then cutting=$(echo "2,3,5");fi
    cut -d';' -f${cutting} ${TMP_DIR}/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.anteilRAREbreed.srt
     sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed} |\
         join -t' ' -o'1.1 1.2 1.3 1.4 1.5 2.2 2.3' -1 5 -2 1 - $TMP_DIR/${breed}.anteilRAREbreed.srt |\
         sort -T ${SRT_DIR} -t' ' -k5,5 |\
         join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 1.7' -1 5 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/${breed}Typisierungsstatus_HD-50K${run}.txt)|\
         sort -T ${SRT_DIR} -t' ' -k5,5 > $TMP_DIR/${breed}.imputeid.brdcd.srt

     echo "Allelfrequenzen filtern"
     if [ ${breed} == 'BSW' ] ; then
	    awk '{if($6 > 0.70 && $7 < 0.3)print "1 "$1}' $TMP_DIR/${breed}.imputeid.brdcd.srt > $WORK_DIR/${breed}_OB-animals.lst
	    awk '{if($6 < 0.30 && $7 > 0.7)print "1 "$1}' $TMP_DIR/${breed}.imputeid.brdcd.srt > $WORK_DIR/${breed}_BS-animals.lst
     else
	    awk '{if($6 > 0.70 && $7 < 0.3)print "1 "$1}' $TMP_DIR/${breed}.imputeid.brdcd.srt > $WORK_DIR/${breed}_SI-animals.lst
	    awk '{if($6 < 0.30 && $7 > 0.7)print "1 "$1}' $TMP_DIR/${breed}.imputeid.brdcd.srt > $WORK_DIR/${breed}_HO-animals.lst
     fi

done

#for rasse in BSWFIFTYK BSWLD HOLFIFTYK HOLLD VMSFIFTYK VMSLD ; do
for rasse in ${1}FIFTYK ${1}LD ; do
   breed=$(echo ${rasse} | cut -b1-3)
    echo $rasse
    if [ ${rasse} == "BSWFIFTYK" ] || [ ${rasse} == "HOLFIFTYK" ] || [ ${rasse} == "VMSFIFTYK" ] ; then
	$BINLIN_DIR/plink_linux64bit_v1.09 --lfile $WORK_DIR/${rasse} --missing-genotype '0' --nonfounders --cow --noweb --make-bed --out $TMP_DIR/${rasse}_binary1st
	if [ ${rasse} == "BSWFIFTYK" ]; then
	    for sub in OB BS; do
		$BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${rasse}_binary1st  --nonfounders --cow --noweb --keep $WORK_DIR/${breed}_${sub}-animals.lst --freq --out $TMP_DIR/${rasse}_${sub}-fuerALLELEFREQ
	    done
	    (awk '{if($5 > 0.005)print $2} ' $TMP_DIR/${rasse}_OB-fuerALLELEFREQ.frq ;
		awk '{if($5 > 0.005)print $2} ' $TMP_DIR/${rasse}_BS-fuerALLELEFREQ.frq ;) | sort -T ${SRT_DIR} -u > $WORK_DIR/${breed}.MAFkeptSNP.lst.uniq
	elif [ ${rasse} == "HOLFIFTYK" ]
	    for sub in SI HO; do
		$BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${rasse}_binary1st  --nonfounders --cow --noweb --keep $WORK_DIR/${breed}_${sub}-animals.lst --freq --out $TMP_DIR/${rasse}_${sub}-fuerALLELEFREQ
	    done
	    (awk '{if($5 > 0.005)print $2} ' $TMP_DIR/${rasse}_SI-fuerALLELEFREQ.frq ;
		awk '{if($5 > 0.005)print $2} ' $TMP_DIR/${rasse}_HO-fuerALLELEFREQ.frq ;) | sort -T ${SRT_DIR} -u > $WORK_DIR/${breed}.MAFkeptSNP.lst.uniq
	else
	    for sub in LI OT; do
		$BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${rasse}_binary1st  --nonfounders --cow --noweb --keep $WORK_DIR/${breed}_${sub}-animals.lst --freq --out $TMP_DIR/${rasse}_${sub}-fuerALLELEFREQ
	    done
	    (awk '{if($5 > 0.005)print $2} ' $TMP_DIR/${rasse}_LI-fuerALLELEFREQ.frq ;
		awk '{if($5 > 0.005)print $2} ' $TMP_DIR/${rasse}_OT-fuerALLELEFREQ.frq ;) | sort -T ${SRT_DIR} -u > $WORK_DIR/${breed}.MAFkeptSNP.lst.uniq
	fi



	$BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${rasse}_binary1st --missing-genotype '0' --nonfounders --cow --noweb --extract $WORK_DIR/${breed}.MAFkeptSNP.lst.uniq --make-bed --out $TMP_DIR/${rasse}_binary
	$BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${rasse}_binary    --missing-genotype '0' --nonfounders --cow --noweb --geno 0.1 --mind 0.25 --make-bed --out $TMP_DIR/${rasse}_impute
	$BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${rasse}_binary    --missing-genotype '0' --nonfounders --cow --noweb --geno 0.1 --mind 0.25 --missing --out $TMP_DIR/${rasse}_fuerListen
	$BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${rasse}_binary    --missing-genotype '0' --nonfounders --cow --noweb --freq --out $TMP_DIR/${rasse}_fuerALLELEFREQ


	#Identifikation der SNPs die wg MAF und Callrate aus dem 50Kfile fliegen, anhaengen an die onlyLDSNPs und zwinge dass Hermanns BH2 SNP drin bleiben unabhaengig der MAF 
	awk '{ sub("\r$", ""); print }' $MAP_DIR/BV_Hap19_1_associatedHap.csv | cut -d';' -f1,2 | tr ';' ' ' | sed -n '2,$p' | sed 's/_//g' | sed 's/-//g' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.forceBH2.keep
	#loesche eventuell zusätziche SNP in der BH2 Region
	cut -d';' -f1,2 $MAP_DIR/BV_Hap19_1_associatedHap.csv | tr ';' ' ' | sed 's/_//g' | sed 's/-//g'  | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.Hermann.bh2map.srt
	(cat $WORK_DIR/BSWFIFTYK.map ; cat $WORK_DIR/BSWLD.map) | awk '{if($1 == 19) print $2,$4}' | sort -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.Inputmap.srt
	bpEINS=$(join -t' ' -o'2.2' -1 1 -2 1 $TMP_DIR/${breed}.Hermann.bh2map.srt $TMP_DIR/${breed}.Inputmap.srt | sort -T ${SRT_DIR} -n  | head -1)
	bpENDE=$(join -t' ' -o'2.2' -1 1 -2 1 $TMP_DIR/${breed}.Hermann.bh2map.srt $TMP_DIR/${breed}.Inputmap.srt | sort -T ${SRT_DIR} -nr | head -1)
	join -t' ' -o'2.1 2.2' -1 1 -2 1 -v2 $TMP_DIR/${breed}.Hermann.bh2map.srt $TMP_DIR/${breed}.Inputmap.srt |\
            awk -v s=${bpEINS} -v t=${bpENDE} '{if($2 >= s && $2 <= t) print $1}' > $TMP_DIR/${breed}.BH2region.butNOTbh2SNPs.txt

        #sammeln der SNPs
	(awk '{if($5 < 0.0051)print $2}' $TMP_DIR/${rasse}_fuerALLELEFREQ.frq;
	    awk '{if($5 > 0.099)print $2}' $TMP_DIR/${rasse}_fuerListen.lmiss) | sort -T ${SRT_DIR} -u > $TMP_DIR/${rasse}_MAFundGENOremoved50Ksnps.srt
	(cat $TMP_DIR/${breed}LD.onlyLD.snps ;
	    cat $TMP_DIR/${breed}.BH2region.butNOTbh2SNPs.txt;
	    cat $TMP_DIR/${rasse}_MAFundGENOremoved50Ksnps.srt) | sort -T ${SRT_DIR} -u  | awk '{print $1,"l"}' | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1' -v1 -1 1 -2 1 - $TMP_DIR/${breed}.forceBH2.keep > $TMP_DIR/${breed}LD.onlyLD.snps.all

    else

#   neu Callrate Korrektur damit keine externen mehr mit extrem Tiefer callrate durchrutschen 10.2.2014, Grenze muss sehr tief (20%) sein, sonst gehen alte 3K Genotypen verloren
    $BINLIN_DIR/plink_linux64bit_v1.09 --lfile $WORK_DIR/${rasse} --missing-genotype '0' --nonfounders --cow --noweb --exclude $TMP_DIR/${rasse}.onlyLD.snps.all --make-bed --out $TMP_DIR/${rasse}_imputetmp
    $BINLIN_DIR/plink_linux64bit_v1.09 --lfile $WORK_DIR/${rasse} --missing-genotype '0' --nonfounders --cow --noweb --exclude $TMP_DIR/${rasse}.onlyLD.snps.all --recodeA --out $TMP_DIR/${rasse}_overlapSNPs
    $BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${rasse}_imputetmp --missing-genotype '0' --nonfounders --cow --noweb --mind 0.80 --make-bed --out $TMP_DIR/${rasse}_impute


    #Map für Mapprep:
    awk '{print $1" L"}' $TMP_DIR/${rasse}.onlyLD.snps.all | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${rasse}onlyLD.srt
    sort -T ${SRT_DIR} -t' ' -k2,2 $TMP_DIR/${rasse}-FIFTYK.overlap.tmp | join -t' ' -o'1.1 1.2 1.3 1.4' -1 2 -2 1 -v1 - $TMP_DIR/${rasse}onlyLD.srt > $TMP_DIR/${rasse}-FIFTYK.overlap.map
   
    fi

    (cat $MAP_DIR/liste_doppelte_SNP_loeschen.txt | sed -e "s/\-//g" | sed -e "s/_//g";
	cat $TMP_DIR/${breed}.BH2region.butNOTbh2SNPs.txt;
	cat $WORK_DIR/snps.nameUnterschiedlich.koordinateIdentisch.${breed} ;
	awk '{if ($1 > 29 || $1 == "X" || $1 == 0 || $4 == 0 ) print $2}' $WORK_DIR/$rasse.map) | sort -T ${SRT_DIR} -u > $TMP_DIR/${rasse}.exclude.snps

    $BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${rasse}_impute --nonfounders --cow --noweb --exclude $TMP_DIR/${rasse}.exclude.snps --make-bed --out $TMP_DIR/${rasse}_impute_reducedSNPs


done

#zwischenschritt fuer BTAwise imputation
#Map für Mapprep: wird benoetigt im fimpute markerprep und genoprep
for razza in ${1} ; do
     join -t' ' -o'1.1 1.2 1.3 1.4' -1 2 -2 2 <(sort -T ${SRT_DIR} -t' ' -k2,2 $WORK_DIR/${razza}FIFTYK.map) <(sort -T ${SRT_DIR} -t' ' -k2,2 $WORK_DIR/${razza}LD.map) > $TMP_DIR/${razza}LD-FIFTYK.overlap.map
done



#mergen 2x auslesen: 1x binary und das 2.x fuer folgendes shellskript
#for breed in BSW HOL VMS; do
for breed in ${1} ; do
    echo $breed
    $BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${breed}FIFTYK_impute_reducedSNPs --bmerge $TMP_DIR/${breed}LD_impute_reducedSNPs.bed $TMP_DIR/${breed}LD_impute_reducedSNPs.bim $TMP_DIR/${breed}LD_impute_reducedSNPs.fam --nonfounders --cow --noweb --recode   --out $WORK_DIR/${breed}merged_
    $BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${breed}FIFTYK_impute_reducedSNPs --bmerge $TMP_DIR/${breed}LD_impute_reducedSNPs.bed $TMP_DIR/${breed}LD_impute_reducedSNPs.bim $TMP_DIR/${breed}LD_impute_reducedSNPs.fam --nonfounders --cow --noweb --make-bed --out $TMP_DIR/${breed}merged_



#zwingen Allel B zu zaehlen
    awk '{print $2" B"}' $WORK_DIR/${breed}merged_.map > $TMP_DIR/${breed}LDFIFTYK.force.Bcount
rm -f $WORK_DIR/${breed}merged_.ped
#    $BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${breed}merged_ --missing-genotype 0 --nonfounders --cow --noweb --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --out $WORK_DIR/${breed}LDFIFTYK_routine_BTAwholeGenome



#chromosomenweise auslesen fuer BH2
    for BTA in $( seq 1 1 29 ) ; do
	$BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${breed}merged_ --missing-genotype 0 --nonfounders --cow --noweb --chr ${BTA} --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --out $WORK_DIR/${breed}LDFIFTYK_routine_BTA${BTA}


	if [ ${breed} == "BSW" ] && [ ${BTA} == 19 ]; then
	   cut -d';' -f1 $MAP_DIR/BV_Hap19_1_associatedHap.csv | sed -e "s/\-//g" | sed -e "s/_//g" | sed -n '2,$p' > $TMP_DIR/BH2.txt
           $BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${breed}merged_ --missing-genotype 0 --nonfounders --cow --noweb --extract $TMP_DIR/BH2.txt --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --out $WORK_DIR/${breed}LDFIFTYK_BH2_BTA19

		   $BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${breed}merged_ --missing-genotype 0 --nonfounders --cow --noweb --chr 19 --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --out $WORK_DIR/${breed}LDFIFTYK_BH2_BTA${BTA}all
	fi
    if [ ${breed} == "HOL" ] && [ ${BTA} == 1 ]; then
	   cut -d';' -f1 $MAP_DIR/HOL_HH2_associatedHapQUALITAS.lst  | sed -e "s/\-//g" | sed -e "s/_//g" | sed -n '2,$p' > $TMP_DIR/HH2.txt
           $BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${breed}merged_ --missing-genotype 0 --nonfounders --cow --noweb --extract $TMP_DIR/HH2.txt --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --out $WORK_DIR/${breed}LDFIFTYK_HH2_BTA${BTA}

		   $BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${breed}merged_ --missing-genotype 0 --nonfounders --cow --noweb --chr ${BTA} --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --out $WORK_DIR/${breed}LDFIFTYK_HH2_BTA${BTA}all
	fi
	if [ ${breed} == "HOL" ] && [ ${BTA} == 9 ]; then
	   cut -d';' -f1 $MAP_DIR/HOL_HH5_associatedHapQUALITAS.lst  | sed -e "s/\-//g" | sed -e "s/_//g" | sed -n '2,$p' > $TMP_DIR/HH5.txt
           $BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${breed}merged_ --missing-genotype 0 --nonfounders --cow --noweb --extract $TMP_DIR/HH5.txt --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --out $WORK_DIR/${breed}LDFIFTYK_HH5_BTA${BTA}

		   $BINLIN_DIR/plink_linux64bit_v1.09 --bfile $TMP_DIR/${breed}merged_ --missing-genotype 0 --nonfounders --cow --noweb --chr ${BTA} --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --out $WORK_DIR/${breed}LDFIFTYK_HH5_BTA${BTA}all
	fi
    done
done


#for breed in BSW HOL VMS ; do
for breed in ${1} ; do

   $BIN_DIR/checkPLINKlogfiles.sh ${breed}

done

echo " "
RIGHT_NOW=$(date)
echo $RIGHT_NOW Ende ${SCRIPT}
