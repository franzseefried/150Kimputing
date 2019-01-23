#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
#set -o errexit


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
#set -o nounset
breed=${1}

##################################



for rasse in ${1}LD ${1}HD ; do
    echo " "
    echo ${rasse}
    breed=$(echo ${rasse} | cut -b1-3)
    echo "Inputfiles fuer das GCTA-PCA programm werden gemacht fuer Dataset ${rasse}"

    (echo "tvdId blut sample.id" ;
	join -t' ' -o'1.2 1.3 2.1' -1 2 -2 5 <(cat $TMP_DIR/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2) <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed})) > $TMP_DIR/${rasse}blut.txt

        
    $FRG_DIR/plink --bfile $TMP_DIR/${rasse} --nonfounders --cow --noweb --geno 0.1 --maf 0.35 --hwe 0.00001 --recode --out $TMP_DIR/${rasse}_PCA
    awk '{if($1 > 29) print $2}' $TMP_DIR/${rasse}_PCA.map > $TMP_DIR/${rasse}_PCA.SNP.exclude
    $FRG_DIR/plink --bfile $TMP_DIR/${rasse} --nonfounders --cow --noweb --exclude $TMP_DIR/${rasse}_PCA.SNP.exclude --geno 0.1 --maf 0.35 --hwe 0.00001 --make-bed --out $TMP_DIR/${rasse}_PCA
    rm -f $TMP_DIR/${rasse}_PCA.ped
    
    $FRG_DIR/gcta64 --bfile $TMP_DIR/${rasse}_PCA --autosome-num 29 --thread-num 30 --make-grm --out $TMP_DIR/${rasse}_PCA 2>&1
    $FRG_DIR/gcta64 --grm $TMP_DIR/${rasse}_PCA --pca 10 --autosome-num 29 --thread-num 30 --out $TMP_DIR/${rasse} 2>&1  
    echo " "
    echo "plot Eigenvalues now"
    Rscript $BIN_DIR/PCAplot.R $TMP_DIR/${rasse}.eigenvec $TMP_DIR/${rasse}blut.txt $RES_DIR/${rasse}.PCA.scores.txt $PDF_DIR/${rasse}pcaPlotMitBlut.pdf
  
#    rm -f $TMP_DIR/${rasse}blut.txt $TMP_DIR/${rasse}_PCA*
#    rm -f $GCA_DIR/${rasse}
done


echo " "
RIGHT_NOW=$(date)
echo $RIGHT_NOW Ende ${SCRIPT}
