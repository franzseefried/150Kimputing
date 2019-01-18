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
set -o pipefail
if ! test -s $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt; then
   echo "you have choosen a fixSNPdatum, where I tried to take the SNPmap now"
   echo "that map $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt does not exist or has size ZERO"
   echo "change parameter or check"
   $BIN_DIR/sendErrorMail.sh $PROG_DIR/linuxPLINKwiFIXSNP.sh $1
   exit 1
fi
breed=${1}




#lese fix die marker aus einem definierten imputationrun:
cat $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt | sed -n '2,$p' | awk '{print $1}'  > $TMP_DIR/${breed}_fixSNP.txt
awk '{if(NR > 1) print $1" B"}' $HIS_DIR/${breed}.RUN${fixSNPdatum}snp_info.txt > $TMP_DIR/${breed}LDFIFTYK.force.Bcount


for rasse in ${1}HD ${1}LD ; do
ls -trl $TMP_DIR/${rasse}*
    $FRG_DIR/plink --bfile $TMP_DIR/${rasse} --nonfounders --cow --noweb --extract $TMP_DIR/${breed}_fixSNP.txt --make-bed --out $TMP_DIR/${rasse}_impute_reducedSNPs
    
    #loeschen damit im Fall einer wiederholung das bin/wait.sh korrekt läuft
    #rm -f $TMP_DIR/${rasse}.bed
done

#mergen 2x auslesen: 1x binary und das 2.x fuer folgendes shellskript

echo "${breed} mergen"
$FRG_DIR/plink --bfile $TMP_DIR/${breed}HD_impute_reducedSNPs --bmerge $TMP_DIR/${breed}LD_impute_reducedSNPs.bed $TMP_DIR/${breed}LD_impute_reducedSNPs.bim $TMP_DIR/${breed}LD_impute_reducedSNPs.fam --nonfounders --cow --noweb --make-bed --out $TMP_DIR/${breed}merged_
$FRG_DIR/plink --bfile $TMP_DIR/${breed}HD_impute_reducedSNPs --bmerge $TMP_DIR/${breed}LD_impute_reducedSNPs.bed $TMP_DIR/${breed}LD_impute_reducedSNPs.bim $TMP_DIR/${breed}LD_impute_reducedSNPs.fam --nonfounders --cow --noweb --recode   --out $WORK_DIR/${breed}merged_


$BIN_DIR/checkPLINKlogfiles.sh ${breed}



echo " "
RIGHT_NOW=$(date)
echo $RIGHT_NOW Ende ${SCRIPT}
